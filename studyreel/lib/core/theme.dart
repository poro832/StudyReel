import 'package:flutter/material.dart';

// 테마와 무관하게 고정인 강조색
const kPrimaryColor = Color(0xFF3182F6); // 토스 블루
const kStreakColor  = Color(0xFFFF8A3D); // 스트릭 오렌지

/// 밝기에 따라 달라지는 색 토큰. `context.col.bg` 형태로 읽는다.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;          // 앱 배경
  final Color surface;     // 카드/표면
  final Color primarySoft; // 블루 틴트 (칩/배경)
  final Color text;        // 본문
  final Color textGray;    // 보조 텍스트
  final Color border;      // 구분선/외곽
  final List<BoxShadow> cardShadow;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.primarySoft,
    required this.text,
    required this.textGray,
    required this.border,
    required this.cardShadow,
  });

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? primarySoft,
    Color? text,
    Color? textGray,
    Color? border,
    List<BoxShadow>? cardShadow,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        primarySoft: primarySoft ?? this.primarySoft,
        text: text ?? this.text,
        textGray: textGray ?? this.textGray,
        border: border ?? this.border,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      textGray: Color.lerp(textGray, other.textGray, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

const _darkColors = AppColors(
  bg: Color(0xFF0B0E14),
  surface: Color(0xFF141B2B),
  primarySoft: Color(0xFF16233B),
  text: Color(0xFFEAF0FB),
  textGray: Color(0xFF9AA7BD),
  border: Color(0xFF222B3D),
  cardShadow: [
    BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

const _lightColors = AppColors(
  bg: Color(0xFFF7F8FA),
  surface: Color(0xFFFFFFFF),
  primarySoft: Color(0xFFE8F1FE),
  text: Color(0xFF191F28),
  textGray: Color(0xFF6B7684),
  border: Color(0xFFE5E8EB),
  cardShadow: [
    BoxShadow(color: Color(0x0F191F28), blurRadius: 12, offset: Offset(0, 4)),
  ],
);

/// `context.col.bg` 처럼 현재 테마의 색을 읽는다.
extension AppColorsX on BuildContext {
  AppColors get col => Theme.of(this).extension<AppColors>()!;
}

ThemeData _baseTheme(Brightness brightness, AppColors colors) => ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        brightness: brightness,
        primary: kPrimaryColor,
        surface: colors.surface,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      extensions: [colors],
      useMaterial3: true,
    );

final darkTheme = _baseTheme(Brightness.dark, _darkColors);
final lightTheme = _baseTheme(Brightness.light, _lightColors);
