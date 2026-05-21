# StudyReel UI 라이트 리디자인 설계

**작성일:** 2026-05-21
**목표:** 다크 몰입형 UI를 밝고 깔끔한 Toss풍 디자인으로 전면 전환. 쇼츠 세로 스와이프 몰입감은 유지(하이브리드).

---

## 1. 결정 사항 요약

| 항목 | 결정 |
|------|------|
| 무드 | 밝고 깔끔 (Toss풍, 카드 중심) |
| 피드 인터랙션 | 하이브리드 — 세로 스와이프 유지 + 밝은 둥근 카드 |
| 포인트 컬러 | 토스 블루 `#3182F6` |
| 테마 밝기 | `Brightness.light` (Material3) |

## 2. 디자인 시스템 (`core/theme.dart` 전면 교체)

### 색상 토큰

```dart
const kBgColor       = Color(0xFFF7F8FA); // 앱 배경 (연회색)
const kSurfaceColor  = Color(0xFFFFFFFF); // 카드/표면
const kPrimaryColor  = Color(0xFF3182F6); // 토스 블루 (포인트)
const kPrimarySoft   = Color(0xFFE8F1FE); // 블루 10% 틴트 (칩 배경 등)
const kTextColor     = Color(0xFF191F28); // 본문 (거의 검정)
const kTextGray      = Color(0xFF6B7684); // 보조 텍스트
const kBorderColor   = Color(0xFFE5E8EB); // 구분선/외곽
const kStreakColor   = Color(0xFFFF8A3D); // 스트릭 🔥 강조 (오렌지)
```

> 기존 상수명 `kBgColor`, `kCardColor`, `kPrimaryColor`, `kTextGray`, `kRedAccent`를 사용하는 코드가 있으므로,
> 호환을 위해 `kCardColor`는 `kSurfaceColor`의 별칭으로 남기거나 일괄 치환한다.
> `kRedAccent`는 제거하고 사용처(폴백 재생 버튼 등)를 `kPrimaryColor`로 교체한다.

### 스타일 규칙

- **모서리:** 카드 16px, 버튼 14px, 칩 12px (라운드)
- **그림자:** 테두리 대신 소프트 섀도우
  `BoxShadow(color: Color(0x0F191F28), blurRadius: 12, offset: Offset(0, 4))`
- **여백:** 화면 좌우 패딩 20px, 카드 내부 16~20px, 요소 간 12~16px
- **타이포:** 헤더 `FontWeight.w700`, 본문 `w500/w400`. 색상은 `kTextColor`/`kTextGray`
- **테마:**
  ```dart
  ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: kBgColor,
    colorScheme: ColorScheme.light(primary: kPrimaryColor, surface: kSurfaceColor),
    useMaterial3: true,
  )
  ```

## 3. 화면별 설계

### 3.1 온보딩 (`onboarding_screen.dart`)
- 흰/연회색 배경, 굵은 다크 타이틀 "어떤 걸\n배우고 싶나요?"
- 안내 문구 `kTextGray`
- 토픽 칩: 흰 카드 + 소프트 섀도우, 미선택 시 `kTextColor` 텍스트 + `kBorderColor` 외곽,
  선택 시 `kPrimaryColor` 채움 + 흰 텍스트
- 하단 "시작하기 →": 활성 시 `kPrimaryColor` 풀폭 라운드(14px) 버튼, 비활성 시 `kBorderColor`
- "N개 선택됨" 카운터 `kTextGray`

### 3.2 피드 (`feed_screen.dart` + `shorts_widget.dart`) — 핵심
- 배경 `kBgColor`
- **상단바:** 투명/연회색, "오늘의 학습"(굵은 다크) + "탐색"(`kTextGray`, 탭 가능) + 우측 아바타(블루 원)
- **영상 영역:** 풀블랙 전체화면이 아니라 **둥근 흰 프레임 카드**(모서리 16px, 소프트 섀도우, 좌우 16px 여백). 카드 안에 YoutubePlayer 또는 폴백.
- **정보 영역:** 영상 카드 아래 흰 카드
  - 블루 틴트(`kPrimarySoft`) 토픽 칩 + `kPrimaryColor` 텍스트
  - 제목: `kTextColor` `w700` 16px
  - 채널: `kTextGray` 13px
  - 액션 행: `♡ 저장`(저장 시 `kPrimaryColor` 채움) · `⤴ 앱에서`(외부 실행)
- **세로 스와이프 유지** (PageView), 활성 페이지만 재생 로직 그대로
- **임베드 실패 폴백:** 라이트 톤 — 썸네일 + 블루 원형 재생버튼 + "인앱 재생 제한, 탭하면 YouTube에서" 안내
- 로딩: `kPrimaryColor` 스피너 / 에러: 흰 카드 + 다시 시도 버튼

### 3.3 탐색 (`explore_screen.dart` + `video_list_tile.dart`)
- 검색바: 흰 배경 라운드(14px) + 소프트 섀도우 + `kPrimaryColor` 검색 아이콘
- 빈 상태/에러: `kTextGray` 안내
- 결과 타일(`VideoListTile`): 흰 카드 + 소프트 섀도우, 좌측 썸네일(라운드) + 우측 제목(`kTextColor`)·채널(`kTextGray`), 탭 시 외부 실행

### 3.4 프로필 (`profile_screen.dart`)
- 스트릭 카드: `kPrimaryColor` → 진한 블루 그라데이션, 흰 텍스트, 🔥 + "N일 연속 학습"
- "저장한 영상" 섹션 헤더 `kTextColor` `w700`
- 저장 목록: `VideoListTile`(라이트) 재사용
- 빈/로딩/에러 상태 라이트 톤

## 4. 변경 파일

| 파일 | 변경 |
|------|------|
| `core/theme.dart` | 전면 교체 (라이트 토큰) |
| `presentation/onboarding/onboarding_screen.dart` | 라이트 칩/버튼 |
| `presentation/feed/feed_screen.dart` | 라이트 상단바/배경/상태 |
| `presentation/feed/shorts_widget.dart` | 둥근 카드 프레임 + 라이트 정보/폴백 |
| `presentation/explore/explore_screen.dart` | 라이트 검색바/상태 |
| `presentation/profile/profile_screen.dart` | 블루 스트릭 카드 |
| `presentation/common/video_list_tile.dart` | 라이트 카드 타일 |

## 5. 비범위 (YAGNI)
- 기능/로직 변경 없음 (피드 데이터·필터·재생·캐싱 그대로)
- 라우팅·프로바이더·리포지토리 변경 없음
- 다크모드 토글은 이번 범위 아님 (라이트 단일)
- 폰트 패키지 추가 없음 (시스템 폰트 유지)

## 6. 테스트 영향
- `widget_test.dart`(온보딩 텍스트 표시)는 텍스트 동일하면 영향 없음 — 색상만 변경
- 단위 테스트(리포지토리/스트릭/토픽)는 UI 무관 → 영향 없음
- 시각 검증은 BlueStacks/실기기 스크린샷으로 수행
