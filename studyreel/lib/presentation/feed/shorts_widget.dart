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

  /// 인앱 임베드가 실패하면 true → 썸네일 + 외부 실행 폴백으로 전환
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
        // 무음 자동재생만 브라우저 정책상 허용됨. 소리 있는 자동재생은
        // onAutoplayBlocked로 막혀 검은 화면이 됨 → 음소거로 시작 후 탭하면 해제.
        mute: true,
        loop: true,
        // [실험] error 152-4 회피: youtube-nocookie.com은 유효한 임베드 호스트라
        // 플레이어가 정상 로드되면서 youtube.com과 다른 도메인이라 152 정책을
        // 우회할 수 있음. (이 패키지는 origin을 host로도 써서 유효 호스트 필수)
        origin: 'https://www.youtube-nocookie.com',
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; SM-F966N) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
      ),
    );
    _sub = _controller.listen((value) {
      // 진짜 임베드 차단(101/150)일 때만 로컬 폴백으로 전환한다.
      // unknown 등 일시 오류로는 전환하지 않는다(전체 피드 캐스케이드 방지).
      const embedBlocked = {
        YoutubeError.notEmbeddable,
        YoutubeError.sameAsNotEmbeddable,
      };
      if (embedBlocked.contains(value.error) && mounted && !_embedFailed) {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // 영상: 둥근 흰 프레임 카드 (소프트 섀도우)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kCardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: _embedFailed
                  ? _buildFallback()
                  : YoutubePlayer(controller: _controller),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(),
        ],
      ),
    );
  }

  /// 인앱 재생이 막힌 영상: 썸네일 + 안내 + 외부 실행
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
                Container(color: kBgColor),
          ),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),
                const Text('인앱 재생이 제한된 영상이에요',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('탭하면 YouTube에서 볼 수 있어요',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.video.topic,
                      style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: kTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(widget.video.channelTitle,
                    style: const TextStyle(color: kTextGray, fontSize: 12)),
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
                          : kTextGray,
                      size: 30,
                    ),
                    const SizedBox(height: 2),
                    Text(widget.video.isBookmarked ? '저장됨' : '저장',
                        style: const TextStyle(color: kTextGray, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => launchYoutube(widget.video.videoId),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, color: kTextGray, size: 26),
                    SizedBox(height: 2),
                    Text('앱에서',
                        style: TextStyle(color: kTextGray, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
