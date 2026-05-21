import 'dart:async';
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
  StreamSubscription<YoutubePlayerValue>? _sub;

  /// 인앱 임베드가 실패하면 true → 썸네일 + 외부 실행 폴백 카드로 전환
  bool _embedFailed = false;

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
    // 임베드 에러(소유자 차단/플레이어 구성 오류 등) 감지 시 폴백 전환
    _sub = _controller.listen((value) {
      if (value.error != YoutubeError.none && mounted && !_embedFailed) {
        setState(() => _embedFailed = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShortsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_embedFailed && widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.playVideo();
      } else {
        _controller.pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _embedFailed ? _buildFallback() : YoutubePlayer(controller: _controller),
        _buildInfoOverlay(),
      ],
    );
  }

  /// 인앱 재생이 막힌 영상: 썸네일 + 안내 + 외부 실행 버튼
  Widget _buildFallback() {
    return GestureDetector(
      onTap: () => launchYoutube(widget.video.videoId),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                Container(color: kCardColor),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: kRedAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text('이 영상은 인앱 재생이 제한돼요',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('탭하면 YouTube에서 이어서 볼 수 있어요',
                    style: TextStyle(color: kTextGray, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
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
                GestureDetector(
                  onTap: () => launchYoutube(widget.video.videoId),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, color: Colors.white, size: 26),
                      SizedBox(height: 2),
                      Text('앱에서',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
