import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/youtube_video.dart';

/// 썸네일 + 제목 + 채널명으로 구성된 가로 영상 타일.
/// 탭하면 앱 안에서 풀스크린으로 재생한다(외부 YouTube로 나가지 않음).
class VideoListTile extends StatelessWidget {
  final YoutubeVideo video;
  const VideoListTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/watch', extra: video),
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.col.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  video.thumbnailUrl,
                  width: 140,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 140,
                    height: 90,
                    color: context.col.bg,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.col.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.col.textGray, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
