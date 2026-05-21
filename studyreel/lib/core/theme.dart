import 'package:flutter/material.dart';

// 라이트 디자인 토큰 (Toss풍)
const kBgColor      = Color(0xFFF7F8FA); // 앱 배경 (연회색)
const kSurfaceColor = Color(0xFFFFFFFF); // 카드/표면
const kCardColor    = kSurfaceColor;     // 기존 사용처 호환 별칭
const kPrimaryColor = Color(0xFF3182F6); // 토스 블루
const kPrimarySoft  = Color(0xFFE8F1FE); // 블루 틴트 (칩 배경)
const kTextColor    = Color(0xFF191F28); // 본문
const kTextGray     = Color(0xFF6B7684); // 보조 텍스트
const kBorderColor  = Color(0xFFE5E8EB); // 구분선/외곽
const kStreakColor  = Color(0xFFFF8A3D); // 스트릭 강조 (오렌지)

// 카드 공통 소프트 섀도우
const kCardShadow = [
  BoxShadow(color: Color(0x0F191F28), blurRadius: 12, offset: Offset(0, 4)),
];

final appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: kBgColor,
  colorScheme: const ColorScheme.light(
    primary: kPrimaryColor,
    surface: kSurfaceColor,
  ),
  textTheme: const TextTheme().apply(
    bodyColor: kTextColor,
    displayColor: kTextColor,
  ),
  useMaterial3: true,
);
