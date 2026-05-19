# ADR-0005: YouTube 재생 — WebView 임베드 대신 url_launcher 외부 실행

- 상태: 채택됨
- 일자: 2026-04-29

## 맥락

[ADR-0004](./ADR-0004-youtube-shorts-pivot.md)로 피드가 YouTube 영상 기반이 되면서
영상 재생 방식을 결정해야 했다. 1순위 후보는 `youtube_player_iframe`(인앱 WebView 임베드).

## 문제

`youtube_player_iframe`이 의존하는 `webview_flutter_android 2.10.4`가
최신 Android Gradle Plugin과 호환되지 않음:

```
Namespace not specified ... webview_flutter_android-2.10.4/android/build.gradle
```

빌드 자체가 실패. 버전 강제 오버라이드는 다른 충돌을 유발할 위험.

## 결정

WebView 임베드를 포기하고 **`url_launcher`로 YouTube 앱/브라우저 외부 실행**한다.
공통 유틸 `core/youtube_launcher.dart`:

```dart
vnd.youtube://<id>  →  실패 시  https://www.youtube.com/watch?v=<id>
```

## 근거

- 빌드 차단 이슈 즉시 해소, 의존성 트리 단순화
- 네이티브 YouTube 앱의 검증된 재생 UX 활용
- BlueStacks/저사양 에뮬레이터에서도 안정 동작 (WebView 렌더링 부담 없음)

## 트레이드오프

- 인앱 몰입 재생 불가 — 앱을 잠시 벗어남
- 캡스톤 범위에서는 안정성 > 인앱 임베드로 판단

## 결과

피드(`ShortsWidget`)·탐색·프로필이 모두 동일 `launchYoutube()` 공유 (DRY).
