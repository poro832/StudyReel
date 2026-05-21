# UI 라이트 리디자인 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 다크 몰입형 UI를 밝은 Toss풍(토스 블루 #3182F6) 디자인으로 전면 전환하되, 피드의 세로 스와이프 몰입감은 유지한다.

**Architecture:** 기능/로직(데이터·필터·재생·캐싱·라우팅·프로바이더)은 일절 변경하지 않고, `core/theme.dart`의 색상 토큰을 라이트로 교체한 뒤 각 화면 위젯의 색상·장식(decoration)만 수정한다. 공유 위젯 `VideoListTile`을 먼저 라이트화하여 explore/profile이 재사용한다.

**Tech Stack:** Flutter, Material3 (Brightness.light), Riverpod (변경 없음)

**검증 방식:** 순수 스타일링이라 신규 단위 테스트는 없다. 각 태스크는 `flutter analyze lib/` 에러 0 + 기존 `flutter test` 그린 유지로 검증하고, 마지막에 에뮬레이터 스크린샷으로 시각 확인한다.

**빌드 명령(한글 경로 우회):**
```bash
flutter build apk --debug --dart-define=YOUTUBE_API_KEY=<키>
# APK는 C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk 에 생성됨
```

---

## 파일 변경 맵

| 파일 | 책임 | 변경 |
|------|------|------|
| `lib/core/theme.dart` | 색상 토큰 + ThemeData | 전면 교체 (라이트) |
| `lib/presentation/common/video_list_tile.dart` | 공유 영상 타일 | 라이트 카드 |
| `lib/presentation/onboarding/onboarding_screen.dart` | 관심사 선택 | 라이트 칩/버튼 |
| `lib/presentation/explore/explore_screen.dart` | 검색 | 라이트 검색바/상태 |
| `lib/presentation/profile/profile_screen.dart` | 프로필 | 블루 스트릭 카드 |
| `lib/presentation/feed/shorts_widget.dart` | 쇼츠 카드 | 둥근 카드 프레임 + 라이트 정보/폴백 |
| `lib/presentation/feed/feed_screen.dart` | 피드 | 라이트 상단바/배경/상태 |

---

## Task 1: 라이트 디자인 토큰 (theme.dart)

**Files:**
- Modify (전면 교체): `lib/core/theme.dart`

- [ ] **Step 1: theme.dart 전체 교체**

```dart
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
```

- [ ] **Step 2: 분석 — kRedAccent 잔존 참조 확인**

Run: `cd studyreel && flutter analyze lib/`
Expected: `kRedAccent`를 참조하던 `shorts_widget.dart`에서 에러 발생 (정의 제거됨). 이는 Task 6에서 해결되므로, **이 시점에선 shorts_widget 외 에러가 없는지만 확인**한다. shorts_widget 관련 에러만 남아야 함.

> 메모: 빠른 진행을 위해 Task 1~6을 모두 수정한 뒤 한 번에 analyze해도 된다. 단독 커밋 시에는 Task 6까지 묶어 커밋한다.

- [ ] **Step 3: 커밋 (Task 6 완료 후 함께 커밋 권장)**

```bash
git add lib/core/theme.dart
git commit -m "feat(ui): 라이트 디자인 토큰으로 theme 전환"
```

---

## Task 2: VideoListTile 라이트화 (공유 위젯)

**Files:**
- Modify (전면 교체): `lib/presentation/common/video_list_tile.dart`

- [ ] **Step 1: video_list_tile.dart 전체 교체**

```dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/youtube_launcher.dart';
import '../../data/models/youtube_video.dart';

/// 썸네일 + 제목 + 채널명으로 구성된 가로 영상 타일.
/// 탭하면 YouTube 앱(또는 브라우저)으로 외부 실행한다.
class VideoListTile extends StatelessWidget {
  final YoutubeVideo video;
  const VideoListTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchYoutube(video.videoId),
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
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
                    color: kBgColor,
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
                      style: const TextStyle(
                          color: kTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kTextGray, fontSize: 11),
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
```

- [ ] **Step 2: 분석**

Run: `cd studyreel && flutter analyze lib/presentation/common/video_list_tile.dart`
Expected: `No issues found!`

---

## Task 3: 온보딩 라이트화

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`

- [ ] **Step 1: 칩 Container decoration 교체 (39~62행 영역)**

`Wrap`의 칩 `GestureDetector` 내부를 아래로 교체:

```dart
                  return GestureDetector(
                    onTap: () => notifier.toggle(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : kSurfaceColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : kBorderColor,
                          width: 1,
                        ),
                        boxShadow: isSelected ? null : kCardShadow,
                      ),
                      child: Text(topic,
                          style: TextStyle(
                              color: isSelected ? Colors.white : kTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ),
                  );
```

- [ ] **Step 2: 타이틀 색상 명시 (29~31행)**

`const Text('어떤 걸\n배우고 싶나요?', ...)`의 스타일에 `color: kTextColor` 추가:

```dart
              const Text('어떤 걸\n배우고 싶나요?',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: kTextColor)),
```

- [ ] **Step 3: 비활성 버튼 배경 (79~80행)**

`disabledBackgroundColor`를 변경:

```dart
                    disabledBackgroundColor: kBorderColor,
```

- [ ] **Step 4: 분석**

Run: `cd studyreel && flutter analyze lib/presentation/onboarding/onboarding_screen.dart`
Expected: `No issues found!`

---

## Task 4: 탐색 라이트화

**Files:**
- Modify: `lib/presentation/explore/explore_screen.dart`

- [ ] **Step 1: AppBar 배경 (build 내 AppBar)**

`AppBar(backgroundColor: kBgColor, ...)` 의 title 텍스트 색상을 명시:

```dart
        title: const Text('탐색',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextColor)),
```

- [ ] **Step 2: 검색 TextField decoration 교체**

`TextField`의 `decoration: InputDecoration(...)`를 아래로 교체:

```dart
              decoration: InputDecoration(
                hintText: '학습 주제나 키워드를 검색하세요',
                hintStyle: const TextStyle(color: kTextGray),
                filled: true,
                fillColor: kSurfaceColor,
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: kPrimaryColor),
                  onPressed: _submit,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
```

그리고 `TextField`의 `style`을 `const TextStyle(color: kTextColor)`로 변경.

- [ ] **Step 2b: 검색 입력 텍스트 색상**

```dart
              style: const TextStyle(color: kTextColor),
```

- [ ] **Step 3: 분석**

Run: `cd studyreel && flutter analyze lib/presentation/explore/explore_screen.dart`
Expected: `No issues found!` (info 레벨 underscores는 무시)

---

## Task 5: 프로필 라이트화 (블루 스트릭)

**Files:**
- Modify: `lib/presentation/profile/profile_screen.dart`

- [ ] **Step 1: AppBar 배경/타이틀**

```dart
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('프로필',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextColor)),
      ),
```

- [ ] **Step 2: "저장한 영상" 헤더 색상**

```dart
          const Text('저장한 영상',
              style: TextStyle(
                  color: kTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
```

- [ ] **Step 3: _StreakCard 그라데이션 교체**

`_StreakCard`의 `Container` `decoration` gradient 색상을 토스 블루 계열로:

```dart
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, Color(0xFF1B64DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
```

(텍스트는 흰색 유지 — 변경 불필요)

- [ ] **Step 4: 분석**

Run: `cd studyreel && flutter analyze lib/presentation/profile/profile_screen.dart`
Expected: `No issues found!`

---

## Task 6: 피드 쇼츠 카드 라이트화 (shorts_widget)

**Files:**
- Modify: `lib/presentation/feed/shorts_widget.dart`

- [ ] **Step 1: build() 레이아웃을 둥근 카드 프레임 + 정보 카드로 교체**

`build` 메서드를 아래로 교체 (플레이어/폴백을 둥근 카드 안에, 정보를 흰 카드로):

```dart
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
          // 정보: 흰 카드
          _buildInfoCard(),
        ],
      ),
    );
  }
```

- [ ] **Step 2: _buildFallback() 라이트 톤으로 교체**

```dart
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
```

- [ ] **Step 3: 기존 _buildInfoOverlay()를 _buildInfoCard()로 교체**

기존 `_buildInfoOverlay()` 메서드 전체를 아래 `_buildInfoCard()`로 교체 (그라데이션 오버레이 → 흰 카드):

```dart
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
                        style:
                            const TextStyle(color: kTextGray, fontSize: 11)),
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
```

> `kRedAccent` 참조가 있던 폴백 재생버튼은 위 Step 2에서 `kPrimaryColor`로 교체됨 → Task 1의 kRedAccent 제거와 정합.

- [ ] **Step 4: 분석**

Run: `cd studyreel && flutter analyze lib/presentation/feed/shorts_widget.dart`
Expected: `No issues found!`

---

## Task 7: 피드 화면 라이트화 (feed_screen)

**Files:**
- Modify: `lib/presentation/feed/feed_screen.dart`

- [ ] **Step 1: extendBodyBehindAppBar 제거 + 상단바 텍스트 색상**

`Scaffold(extendBodyBehindAppBar: true, ...)` 에서 `extendBodyBehindAppBar`를 제거(또는 false)하고, AppBar `backgroundColor`를 `kBgColor`로, "오늘의 학습"·"탐색" 텍스트 색상을 명시:

```dart
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextColor)),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => context.push('/explore'),
              child: const Text('탐색',
                  style: TextStyle(fontSize: 16, color: kTextGray)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: kPrimaryColor,
                child: Text('나',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
```

- [ ] **Step 2: 에러 상태 "다시 시도" 카드 + 로딩 색상**

`error:` 분기의 Column을 흰 카드 톤으로(텍스트 `kTextGray` 유지, 버튼은 기본 테마 블루). 변경 최소 — `loading:` 스피너는 테마 primary를 자동 사용하므로 그대로 둔다. 별도 코드 변경 없으면 이 스텝은 생략 가능.

- [ ] **Step 3: 분석**

Run: `cd studyreel && flutter analyze lib/`
Expected: `No issues found!` (info 레벨 제외, 에러 0)

---

## Task 8: 통합 검증 + 커밋

**Files:** 없음 (검증/커밋)

- [ ] **Step 1: 전체 분석**

Run: `cd studyreel && flutter analyze lib/ test/`
Expected: 에러 0 (info 레벨만 허용)

- [ ] **Step 2: 전체 테스트 (회귀 확인)**

Run: `cd studyreel && flutter test`
Expected: `All tests passed!` (17/17). 특히 `widget_test.dart`의 온보딩 텍스트 검증이 통과해야 함.

- [ ] **Step 3: 빌드 + 에뮬레이터 설치 + 시각 확인**

```bash
flutter build apk --debug --dart-define=YOUTUBE_API_KEY=AIzaSyDO8_s7nPNeLBod4Tqy_vnNqkvry7P1FHg
adb -s 127.0.0.1:5555 install -r C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk
```

스크린샷 확인 항목:
- 온보딩: 흰 배경, 칩 선택 시 블루 채움, 시작하기 블루 버튼
- 피드: 연회색 배경 + 둥근 흰 영상 카드 + 흰 정보 카드(블루 토픽 칩)
- 탐색: 흰 검색바, 흰 결과 카드
- 프로필: 블루 그라데이션 스트릭 카드

- [ ] **Step 4: 커밋**

```bash
git add lib/
git commit -m "feat(ui): 밝은 Toss풍 라이트 디자인으로 전면 리스킨"
```

---

## 자체 검토 메모
- 스펙의 모든 화면(온보딩/피드/탐색/프로필) + 토큰 + 공유 타일 커버됨.
- `kRedAccent` 제거(Task1) ↔ shorts_widget 폴백 버튼 교체(Task6) 정합 확인.
- `kCardColor` 별칭 유지로 누락 참조 컴파일 에러 방지.
- 기능/로직 무변경 → 단위 테스트 영향 없음, widget_test 온보딩 텍스트 유지.
