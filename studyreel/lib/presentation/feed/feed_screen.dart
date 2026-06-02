import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/youtube_video.dart';
import '../../domain/topic_provider.dart';
import '../../domain/youtube_provider.dart';
import 'shorts_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _refreshing = false;

  /// 가변 상태(youtubeVideosProvider)에 시드한 토픽 키. 토픽이 바뀌면
  /// 키가 달라져 새 목록으로 다시 시드한다.
  String? _seededKey;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 현재 토픽으로 새 영상을 강제로 받아와 피드를 갱신한다.
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final topics = ref.read(selectedTopicsProvider).toList()..sort();
    try {
      final fresh =
          await ref.read(youtubeRepositoryProvider).fetchAndCache(topics);
      if (!mounted) return;
      ref.read(youtubeVideosProvider.notifier).state = fresh;
      _currentIndex = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로고침에 실패했어요. 잠시 후 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(selectedTopicsProvider).toList()..sort();
    final key = topics.join('|');
    final videosAsync = ref.watch(youtubeFeedProvider(key));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // 영상이 AppBar 뒤까지 풀화면으로
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => context.push('/explore'),
              child: const Text('탐색',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
            ),
            const Spacer(),
            if (_refreshing)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: '새로고침',
              ),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: kPrimaryColor,
                child: Text('나',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
      body: videosAsync.when(
        data: (fetchedVideos) {
          // provider를 항상 watch해야 갱신이 리빌드를 트리거한다.
          final stateVideos = ref.watch(youtubeVideosProvider);

          // 토픽 키가 바뀌면(또는 최초) 가변 상태를 새 목록으로 시드한다.
          if (_seededKey != key) {
            _seededKey = key;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref.read(youtubeVideosProvider.notifier).state = fetchedVideos;
              _currentIndex = 0;
              if (_pageController.hasClients) _pageController.jumpToPage(0);
            });
            return _buildPager(fetchedVideos);
          }

          if (stateVideos.isEmpty) {
            return const Center(
              child: Text('재생 가능한 영상이 없습니다.',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return _buildPager(stateVideos);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('영상을 불러오지 못했습니다.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(youtubeFeedProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPager(List<YoutubeVideo> list) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: list.length,
      onPageChanged: (i) => setState(() => _currentIndex = i),
      itemBuilder: (context, index) {
        final video = list[index];
        return ShortsWidget(
          key: ValueKey(video.videoId),
          video: video,
          isActive: index == _currentIndex,
          onBookmark: () {
            final updated = video.copyWith(isBookmarked: !video.isBookmarked);
            final newList = [...ref.read(youtubeVideosProvider)];
            final i = newList.indexWhere((v) => v.videoId == video.videoId);
            if (i != -1) newList[i] = updated;
            ref.read(youtubeVideosProvider.notifier).state = newList;
            ref
                .read(youtubeRepositoryProvider)
                .toggleBookmark(video.videoId, updated.isBookmarked);
          },
        );
      },
    );
  }
}
