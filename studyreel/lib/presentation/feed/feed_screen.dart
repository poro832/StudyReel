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
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(selectedTopicsProvider).toList()..sort();
    final videosAsync = ref.watch(youtubeFeedProvider(topics.join('|')));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextColor)),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => context.push('/explore'),
              child: const Text('탐색',
                  style: TextStyle(fontSize: 16, color: kTextGray)),
            ),
            const Spacer(),
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
          // provider를 항상 watch해야 제거 업데이트가 리빌드를 트리거한다.
          final stateVideos = ref.watch(youtubeVideosProvider);

          // 최초 1회만 provider를 캐시/패치 결과로 초기화. 이후엔 provider
          // 상태가 단일 소스 — 재생 실패 영상 제거가 그대로 반영된다.
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(youtubeVideosProvider.notifier).state = fetchedVideos;
            });
            return _buildPager(fetchedVideos);
          }

          if (stateVideos.isEmpty) {
            return const Center(
              child: Text('재생 가능한 영상이 없습니다.',
                  style: TextStyle(color: kTextGray)),
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
                  style: TextStyle(color: kTextGray)),
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
            final updated =
                video.copyWith(isBookmarked: !video.isBookmarked);
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
