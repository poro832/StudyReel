import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/youtube_launcher.dart';
import '../../data/models/youtube_video.dart';

class ShortsWidget extends StatelessWidget {
  final YoutubeVideo video;
  final VoidCallback onBookmark;

  const ShortsWidget({
    super.key,
    required this.video,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchYoutube(video.videoId),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 썸네일 배경
          Image.network(
            video.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: kCardColor),
          ),
          // 어두운 오버레이
          Container(color: Colors.black45),
          // 중앙 재생 버튼
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 44),
            ),
          ),
          // 하단 정보 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
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
                          child: Text(video.topic,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(video.channelTitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.play_circle_outline,
                                color: kRedAccent, size: 14),
                            const SizedBox(width: 4),
                            const Text('탭하여 YouTube에서 보기',
                                style: TextStyle(
                                    color: kRedAccent, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onBookmark,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          video.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: video.isBookmarked
                              ? kPrimaryColor
                              : Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video.isBookmarked ? '저장됨' : '저장',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
