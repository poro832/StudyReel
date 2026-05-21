import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../core/youtube_launcher.dart';
import '../../data/models/youtube_video.dart';

class ShortsWidget extends StatefulWidget {
  final YoutubeVideo video;
  final bool isActive;
  final VoidCallback onBookmark;

  const ShortsWidget({
    super.key,
    required this.video,
    required this.isActive,
    required this.onBookmark,
  });

  @override
  State<ShortsWidget> createState() => _ShortsWidgetState();
}

class _ShortsWidgetState extends State<ShortsWidget> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoId,
      autoPlay: widget.isActive,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        mute: false,
        loop: true,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ShortsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.playVideo();
      } else {
        _controller.pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 인앱 YouTube 플레이어
        YoutubePlayer(controller: _controller),

        // 하단 정보 오버레이 (탭 영역 침범 안 하도록 IgnorePointer 영역 분리)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(widget.video.topic,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.video.channelTitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: widget.onBookmark,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.video.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: widget.video.isBookmarked
                                  ? kPrimaryColor
                                  : Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.video.isBookmarked ? '저장됨' : '저장',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // YouTube 앱에서 열기 (선택)
                      GestureDetector(
                        onTap: () => launchYoutube(widget.video.videoId),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new,
                                color: Colors.white, size: 26),
                            SizedBox(height: 2),
                            Text('앱에서',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
