import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// StudyReel 브랜드 로딩 인디케이터.
/// 그라데이션 재생 마크 둘레로 스피너가 도는 형태 + 선택적 라벨.
class BrandedLoader extends StatelessWidget {
  final String? label;

  /// 어두운 배경(피드 등) 위에 올릴 때 true → 라벨을 밝게.
  final bool onDark;

  const BrandedLoader({super.key, this.label, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = onDark ? Colors.white70 : context.col.textGray;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, Color(0xFF7E4DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(label!,
                style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
