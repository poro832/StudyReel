import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/youtube_video.dart';
import '../../domain/youtube_provider.dart';
import '../feed/shorts_widget.dart';

/// 단일 영상을 앱 안에서 풀스크린으로 재생한다.
/// 탐색·저장한 영상·최근 본 영상에서 진입(외부 YouTube로 나가지 않음).
/// 재생이 막힌 영상은 ShortsWidget 폴백이 "YouTube에서 보기"로 안내한다.
class WatchScreen extends ConsumerStatefulWidget {
  final YoutubeVideo video;
  const WatchScreen({super.key, required this.video});

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  late YoutubeVideo _video;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
  }

  void _toggleBookmark() {
    final updated = _video.copyWith(isBookmarked: !_video.isBookmarked);
    setState(() => _video = updated);
    ref
        .read(youtubeRepositoryProvider)
        .toggleBookmark(updated.videoId, updated.isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ShortsWidget(
              key: ValueKey(_video.videoId),
              video: _video,
              isActive: true,
              onBookmark: _toggleBookmark,
              onWatched: () =>
                  ref.read(youtubeRepositoryProvider).recordWatched(_video),
            ),
          ),
          // 뒤로가기
          Positioned(
            top: 0,
            left: 4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: '뒤로',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
