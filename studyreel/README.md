# 📚 StudyReel

> **YouTube Shorts를 "교육용 피드"로 — 인앱 세로 스와이프 학습 앱**
> 관심 토픽의 짧은 학습 영상을, 앱을 떠나지 않고 **소리·자동재생으로 바로** 보는 Flutter 모바일 앱

`Flutter` · `Riverpod` · `Firebase` · `YouTube Data API` · `TDD`

---

## 한눈에

- **무엇** — 토픽을 고르면 교육용 YouTube Shorts가 세로 피드로 흐르고, **앱 안에서 소리와 함께 자동재생**됩니다. 틱톡/릴스의 소비 경험을 *학습 콘텐츠*로 바꾼 앱.
- **왜 어려웠나** — YouTube는 Shorts의 서드파티 임베드를 막아둡니다(`error 152`). 이걸 뚫지 못하면 "인앱 학습 피드"라는 컨셉 자체가 성립하지 않습니다.
- **어떻게 풀었나** — 임베드 호스트를 `youtube-nocookie`로 교체해 152를 우회하고, **실기기(Galaxy Z Fold7)에서 직접 검증**했습니다.
- **어떻게 만들었나** — 1인 개발 + **다중 AI(Claude/GPT/Gemini) 오케스트레이션**, TDD(19개 테스트), ADR 기반 의사결정.

---

## 🔥 엔지니어링 하이라이트

> 이 프로젝트의 핵심 가치는 "앱을 만들었다"가 아니라 **"막힌 문제를 가설–검증으로 뚫어냈다"** 입니다.

### 1. YouTube Shorts 인앱 재생 — `error 152` 돌파
- **문제** — 검색되는 거의 모든 Shorts가 인앱 임베드 시 `error 152-4 (This video is unavailable)`로 차단. YouTube Data API의 `embeddable=true` 플래그조차 신뢰할 수 없었음(통과시켜 놓고 런타임에 152).
- **오진 → 교정** — 처음엔 "WebView가 영상을 합성하지 못한다 / autoplay가 막힌다"로 진단했으나, **실기기에서 YouTube 에러 UI가 또렷이 렌더되는 것**을 보고 합성·재생이 아니라 *콘텐츠 측 임베드 정책*이 원인임을 규명.
- **해결** — 패키지가 `origin`을 임베드 `host`로도 사용한다는 점을 소스에서 확인하고, 호스트를 `www.youtube.com` → **`www.youtube-nocookie.com`** 으로 교체 → 152 소멸, 인앱 재생 성공.
- **교훈** — ① API 플래그를 맹신하지 말 것 ② 에뮬레이터(BlueStacks)는 WebView 영상 합성을 못 해 검증에 부적합 → **실기기 검증 필수**.

### 2. 자동재생 정책 — 가설을 데이터로 폐기
- "소리 켠 자동재생은 브라우저 정책(`onAutoplayBlocked`)으로 막혀 검은 화면이 된다"는 가설을 세웠으나, 152 해결 후 실측해 보니 `mediaPlaybackRequiresUserGesture(false)` 설정 덕에 **소리까지 정상 자동재생**됨을 확인 — 과거의 "검은 화면"은 사실 152였음이 드러나 가설을 폐기.
- 스와이프 시 다음 영상이 `cued`로 멈추는 문제는, 플레이어 상태가 `cued`가 되는 순간 즉시 재생하도록 처리해 **틱톡식 끊김 없는 자동재생** 구현.

### 3. 콘텐츠 품질 & 캐시 전략
- `"토픽 쇼츠"` + 조회수순 정렬이 예능을 끌어와 학습에 부적합 → **학습 키워드(강의/개념/핵심 요약)** + `relevance` 정렬로 교정.
- YouTube API 무료 할당량(10k units/day) 보호를 위해 **Firestore 캐싱**. 토픽 인지 캐시 + 새로고침 시 캐시 교체(북마크 보존)로 *"새 카테고리/새로고침 = 새 영상"* 을 보장.

---

## 🎬 사용자 플로우

```
온보딩 (관심사 3개+ 선택)
    ↓
인앱 세로 피드 (스와이프 → 다음 영상 자동재생, 소리 ON)
    ↓
북마크 저장 · 새로고침으로 새 영상
    ↓
프로필에서 다시보기 + 학습 스트릭
```

---

## 🏗 기술 스택

| 영역 | 기술 |
|------|------|
| **프레임워크** | Flutter 3.35.4 (Android 타깃) |
| **상태관리** | Riverpod (Notifier · FutureProvider.family · StateProvider) |
| **라우팅** | go_router (선언형 라우팅) |
| **백엔드** | Firebase (Auth · Cloud Firestore) |
| **콘텐츠 API** | YouTube Data API v3 (search · videos.list) |
| **인앱 플레이어** | youtube_player_iframe (WebView IFrame, `youtube-nocookie` 호스트) |
| **외부 실행** | url_launcher (탐색 화면 → YouTube 앱 연동) |
| **테스트** | flutter_test · fake_cloud_firestore · firebase_auth_mocks (19 tests) |

---

## 🗂 프로젝트 구조

```
studyreel/
├── lib/
│   ├── core/                      # 테마, 라우터, youtube_launcher
│   ├── data/
│   │   ├── models/                # YoutubeVideo
│   │   ├── repositories/          # Youtube/Streak/Auth Repository
│   │   └── services/              # YoutubeService (YouTube Data API)
│   ├── domain/                    # Riverpod 프로바이더
│   ├── presentation/
│   │   ├── onboarding/            # 관심사 선택 화면
│   │   ├── feed/                  # 인앱 Shorts 피드 (ShortsWidget)
│   │   ├── explore/               # 키워드 검색 화면
│   │   ├── profile/               # 프로필 + 학습 스트릭
│   │   └── common/                # 공유 위젯
│   └── main.dart
├── docs/                          # setup/deploy/testing/architecture + blog
├── .planning/decisions/           # ADR 0001~0005
└── android/
```

---

## 🚀 실행 방법

```bash
flutter pub get

# 디버그 빌드 (API 키는 빌드 타임 --dart-define으로 주입)
flutter build apk --debug --dart-define=YOUTUBE_API_KEY=<your_youtube_key>

# 한글 경로 우회로 APK는 아래 경로에 생성됨
adb install -r C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk
```

> 자세한 절차: [`docs/setup.md`](docs/setup.md) · [`docs/deploy.md`](docs/deploy.md)
> 한글 경로에서 `impellerc.exe` 크래시를 피하려고 `android/app/build.gradle.kts`에서 `buildDirectory`를 `C:/temp/...`로 리다이렉트합니다. ("Gradle build failed to produce an .apk file" 메시지는 정상 — APK는 위 경로에 생성됨)

---

## 📋 진행 현황

### ✅ 완료
- 온보딩 — 관심사 선택 (Wrap chip + 3개 이상 검증)
- **인앱 Shorts 피드** — `error 152` 돌파, 소리 자동재생, 스와이프 시 다음 영상 자동재생
- **콘텐츠 큐레이션** — 학습 키워드 검색 + relevance 정렬로 예능 영상 배제
- **새로고침 / 토픽 인지 캐시** — 새 카테고리·새로고침 = 새 영상 (Firestore 캐싱, 북마크 보존)
- 탐색/검색 화면 · 프로필 + 학습 스트릭 (결정적 테스트 포함)
- 문서화 (setup/deploy/testing/architecture + ADR 5건)

### 🔜 남은 과제
- 피드 UI 9:16 풀화면 리디자인
- Firestore 보안 규칙 강화 (현재 테스트 모드)
- 자동 integration_test, Google 로그인 UI 연결(현재 `guest` UID 폴백)

---

## 💡 주요 설계 결정 (ADR)

| ADR | 결정 | 핵심 사유 |
|-----|------|-----------|
| [0001](.planning/decisions/ADR-0001-flutter.md) | Flutter 채택 | 단일 코드베이스 + 세로 피드 구현 용이 |
| [0002](.planning/decisions/ADR-0002-firebase.md) | Firebase Auth + Firestore | 서버리스, 사용자별 문서 모델 |
| [0003](.planning/decisions/ADR-0003-no-cloud-functions.md) | Cloud Functions 미사용 | Blaze 유료 회피, 클라이언트 직접 호출 |
| [0004](.planning/decisions/ADR-0004-youtube-shorts-pivot.md) | Gemini 카드 → YouTube 피드 | Gemini 무료 토큰 한도, 컨셉 정합성 |
| [0005](.planning/decisions/ADR-0005-url-launcher-vs-webview.md) | (초기) WebView 대신 url_launcher | 당시 webview AGP 비호환 |

> **ADR-0005는 이후 재검토됨** — "인앱 재생이 안 되면 학습 피드의 의미가 없다"는 요구로, 피드는 `youtube_player_iframe`(+`youtube-nocookie` 호스트) **인앱 재생으로 전환**, 탐색 화면만 외부 실행을 유지합니다. 전 과정은 [`docs/blog/2026-05-26-youtube-shorts-inapp-152.md`](docs/blog/2026-05-26-youtube-shorts-inapp-152.md) 참고.

---

## 🛠 개발 워크플로우

가설–검증 기반으로 개발했습니다:
1. **brainstorming** — 기능/컨셉 설계 탐색
2. **writing-plans** — TDD 기반 단계별 구현 플랜
3. **executing-plans** — 작은 단위 구현 + 커밋
4. **systematic-debugging** — 버그는 추측이 아니라 가설–최소검증으로 (← `error 152` 돌파의 핵심)

> 1인 개발 과정에서 Claude·GPT·Gemini를 **역할별로 나눠 쓰고 출력을 교차검증**했습니다. (예: `youtube-nocookie` 해법은 외부 AI 제안 → 소스 검증 → 실기기 확인으로 채택)

---

## 📄 라이선스

학습용 프로젝트 (신구대학교 클라우드 캡스톤)

---

**Made with Claude Code 🤖**
