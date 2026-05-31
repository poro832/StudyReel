---
title: "YouTube Shorts를 앱 안에서 재생하기 — error 152를 뚫은 기록"
tags: [Flutter, YouTube, WebView, 트러블슈팅, AI협업]
date: 2026-05-26
---

# YouTube Shorts를 앱 안에서 재생하기 — `error 152`를 뚫은 기록

> **TL;DR** — YouTube Shorts를 Flutter 앱에 임베드하면 `error 152-4 (This video is unavailable)`로 막힌다. API의 `embeddable` 플래그도 거짓말을 한다. 원인은 "Shorts의 서드파티 임베드 차단" 정책이었고, **임베드 호스트를 `youtube.com` → `youtube-nocookie.com`으로 바꾸니 해결**됐다. 이 글은 그 과정을 — 잘못 짚은 결론들까지 포함해 — 솔직하게 적은 트러블슈팅 기록이다.

## 배경: "인앱이 안 되면 의미가 없다"

[StudyReel](https://github.com/poro832/StudyReel)은 *교육용 YouTube Shorts를 틱톡처럼 세로로 넘겨 보는* 학습 앱이다. 핵심은 **앱 안에서의 재생**이다. 탭할 때마다 YouTube 앱으로 튕겨 나간다면, 그건 그냥 "YouTube 썸네일 모음"이지 학습 피드가 아니다.

그래서 `youtube_player_iframe`으로 인앱 플레이어를 붙였는데 — 영상이 안 나왔다.

## 1차 벽: `error 152-4`

실기기에서 피드를 열면 플레이어 자리에 이게 떴다.

```
This video is unavailable
Error code: 152 - 4
Watch video on YouTube
```

특이한 건 `onReady`는 정상 발생하는데, 재생 직전 `onError`가 `UNKNOWN`으로 떨어진다는 점이었다. 그리고 **YouTube Data API는 이 영상을 `embeddable: true`로 응답**했다. 즉 API를 믿고 필터링해도 런타임에 막힌다.

## 잘못 짚은 결론들 (정직하게)

처음엔 엉뚱한 데를 팠다.

- **"WebView가 영상 surface를 합성 못 한다"** — 폴더블 멀티 디스플레이 / 에뮬레이터 합성 버그라고 의심.
- **"소리 켠 autoplay가 정책으로 막혀 검은 화면이 된다"** — 패키지 소스에서 `onAutoplayBlocked` 핸들러를 발견하고 그럴듯하다고 판단.

둘 다 틀렸다. 결정적 단서는 **실기기에서 YouTube의 "unavailable" 에러 UI가 또렷하게 렌더되는 것**이었다. UI가 멀쩡히 그려진다는 건 → WebView 합성도, 페이지 로드도 정상이라는 뜻. 문제는 렌더링이 아니라 **콘텐츠 측 정책**이었다.

> 교훈 ①: **"검은 화면"과 "에러 UI가 보이는 화면"은 전혀 다른 증상이다.** 후자는 플레이어가 살아있다는 강력한 신호다.

## 진짜 원인: Shorts는 임베드가 막혀 있다

서로 다른 채널·토픽의 Shorts 3개를 연속으로 확인했다 — **전부 152.** `#shorts` 태그가 붙은 영상들이었다. YouTube는 Shorts의 서드파티 임베드를 의도적으로 제한한다. API의 `embeddable` 플래그는 이걸 반영하지 않는다.

여기서 한 번 절망했다. "Shorts 폼"과 "인앱 재생"은 양립 불가처럼 보였으니까.

## 돌파구: 외부 AI 제안을 가져와 검증하다

막혔을 때 GPT/Gemini에 같은 증상을 물어 답을 모아 왔다. 핵심 힌트는 *"`origin`/referrer 정책 때문이며, 임베드 호스트를 바꾸면 풀릴 수 있다"* 였다. 단, 답변들은 **서로 충돌**했다 — 어떤 답은 "내 앱 도메인을 origin으로", 어떤 답은 "`youtube-nocookie.com`을 쓰라"고 했다. 그대로 믿지 않고 직접 검증했다.

### 함정: 이 패키지는 `origin`을 `host`로도 쓴다

`youtube_player_iframe` 소스를 열어 보니 결정적이었다.

```dart
// youtube_player_controller.dart (요지)
final playerData = {
  ...
  'host': params.origin ?? 'https://www.youtube.com',
};
await webViewController.loadHtmlString(html, baseUrl: params.origin);
```

`origin`과 `host`는 의미가 다르다.
- `origin` — 임베드하는 쪽(내 앱) 도메인. postMessage 보안용.
- `host` — **YouTube 플레이어를 불러올 도메인**. (`youtube.com` 또는 `youtube-nocookie.com`)

그런데 이 패키지는 둘을 같은 값으로 쓴다. 그래서 내가 `origin: 'https://studyreel.app'`로 줬더니 → `host`까지 `studyreel.app`이 되어 플레이어를 `studyreel.app/embed/...`에서 찾으려다 **깨진 화면**이 됐다. (152는 사라졌지만 그건 "해결"이 아니라 "더 일찍 망가진 것"이었다.)

### 정답: `youtube-nocookie.com`

```dart
YoutubePlayerController.fromVideoId(
  videoId: videoId,
  autoPlay: isActive,
  params: const YoutubePlayerParams(
    mute: false,
    // 유효한 임베드 호스트 + youtube.com과 다른 도메인 → 152 우회
    origin: 'https://www.youtube-nocookie.com',
    userAgent: 'Mozilla/5.0 ... Chrome/126 Mobile Safari/537.36',
  ),
);
```

`youtube-nocookie.com`은 **실제로 유효한 YouTube 임베드 호스트**라 플레이어가 정상 로드되고, 동시에 `youtube.com`과 **다른 도메인**이라 152 정책을 우회했다. 실기기에서 — 아까 152가 떴던 바로 그 영상이 — 자막과 함께 재생됐다.

> 교훈 ②: **AI 답변은 가져와서 검증하는 것**이지 복붙하는 게 아니다. 충돌하는 답 중 *왜* 한쪽이 맞는지(여기선 host의 유효성)를 코드로 따져야 한다.

## 보너스로 풀린 것들

152가 풀리자 다른 것도 따라왔다.

- **소리 자동재생** — "autoplay 차단" 가설은 틀렸다. 패키지가 설정하는 `mediaPlaybackRequiresUserGesture(false)` 덕에 소리까지 자동재생됐다. 과거의 "검은 화면"은 전부 152였던 것.
- **스와이프 자동재생** — 다음 영상이 `cued`로 멈추는 문제는, 플레이어 상태가 `cued`가 되는 순간 즉시 재생하도록 리스너에서 처리:

```dart
controller.listen((value) {
  if (widget.isActive && value.playerState == PlayerState.cued) {
    controller.playVideo(); // 넘기면 바로 재생 (틱톡식)
  }
});
```

- **검증 환경** — BlueStacks(에뮬레이터)는 WebView 영상 합성을 못 해 *영상이 재생돼도 검은 화면*이었다. 에뮬레이터로는 이 문제를 영영 못 풀었을 것이다. **실기기 검증이 답이었다.**

## 정리: 5가지 교훈

1. **API 플래그를 맹신하지 말 것.** `embeddable: true`도 거짓일 수 있다.
2. **증상을 구분할 것.** 검은 화면 ≠ 에러 UI. 에러 UI가 보이면 플레이어는 살아있다.
3. **에뮬레이터는 WebView 영상 검증에 부적합.** 실기기에서 확인하라.
4. **라이브러리 소스를 읽어라.** `origin`을 `host`로도 쓰는 구현 디테일이 함정의 핵심이었다.
5. **AI는 조율하고 검증하는 도구.** 충돌하는 제안 중 옳은 것을 코드로 가려내는 게 사람의 몫이다.

---

### 이력서/포트폴리오용 한 줄 (복붙용)

- YouTube Shorts 인앱 재생을 막던 `error 152`를, 라이브러리 소스 분석으로 `origin/host` 동작을 파악해 **`youtube-nocookie` 호스트로 우회**하고 실기기(Galaxy Z Fold7)에서 검증 — 컨셉의 핵심 기능을 살림.
- "WebView 합성 불가 / autoplay 차단" 등 **잘못된 가설을 실측 데이터로 폐기**하며 근본 원인(콘텐츠 측 임베드 정책)을 규명한 가설–검증형 디버깅.
- Claude·GPT·Gemini를 **역할별로 나눠 쓰고 출력을 교차검증**하는 AI 협업 워크플로우로 1인 개발.
- Flutter · Riverpod · go_router · Firebase(Firestore 캐싱) · YouTube Data API · TDD(19 tests).

---

*StudyReel — 신구대 클라우드 캡스톤 / Flutter. 코드: github.com/poro832/StudyReel*
