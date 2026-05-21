import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(selectedTopicsProvider).toList()..sort();
    final videosAsync = ref.watch(youtubeFeedProvider(topics.join('|')));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => context.push('/explore'),
              child: const Text('탐색',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
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
          final videos = ref.watch(youtubeVideosProvider);
          final list = videos.isEmpty ? fetchedVideos : videos;

          if (videos.isEmpty && fetchedVideos.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(youtubeVideosProvider.notifier).state = fetchedVideos;
            });
          }

          if (list.isEmpty) {
            return const Center(
              child: Text('검색된 영상이 없습니다.',
                  style: TextStyle(color: kTextGray)),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => ShortsWidget(
              video: list[index],
              isActive: index == _currentIndex,
              onBookmark: () {
                final updated = list[index]
                    .copyWith(isBookmarked: !list[index].isBookmarked);
                final newList = [...list];
                newList[index] = updated;
                ref.read(youtubeVideosProvider.notifier).state = newList;
                ref
                    .read(youtubeRepositoryProvider)
                    .toggleBookmark(updated.videoId, updated.isBookmarked);
              },
            ),
          );
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
}
