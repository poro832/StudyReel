# 📚 StudyReel

> **YouTube Shorts/Reels 스타일로 즐기는 학습 영상 피드**
> 관심 분야의 짧은 학습 영상을 세로 스크롤로 빠르게 소비하는 모바일 앱

---

## ✨ 컨셉

대학생이 **틱톡/릴스/쇼츠처럼 가볍게 학습 콘텐츠를 소비**할 수 있도록 설계된 Flutter 앱입니다.
기존 SNS의 도파민 루프를 교육 영상으로 대체하여, 짧은 시간에 의미 있는 학습 경험을 제공합니다.

### 핵심 가치
- 🎯 **관심사 기반 큐레이션** — 토픽 선택 → 맞춤 학습 영상 추천
- ⚡ **2분 이내 학습** — Shorts 형태의 짧고 임팩트 있는 콘텐츠
- 🔖 **북마크 & 학습 기록** — 좋은 영상 저장, 학습 스트릭 유지
- 🤖 **AI 보조 학습 카드** — Gemini가 생성하는 요약 카드 + 퀴즈

---

## 🎬 사용자 플로우

```
온보딩 (관심사 3개+ 선택)
    ↓
YouTube Shorts 피드 (세로 스와이프)
    ↓
탭하면 YouTube 앱에서 영상 재생
    ↓
저장/북마크 → 프로필에서 다시보기
```

---

## 🏗 기술 스택

| 영역 | 기술 |
|------|------|
| **프레임워크** | Flutter 3.35.4 (Android 타깃) |
| **상태관리** | Riverpod (Notifier, FutureProvider, StateProvider) |
| **라우팅** | go_router (선언형 라우팅) |
| **백엔드** | Firebase (Auth, Firestore) |
| **콘텐츠 API** | YouTube Data API v3 |
| **외부 실행** | url_launcher (YouTube 앱 연동) |
| **테스트** | mocktail, fake_cloud_firestore, firebase_auth_mocks |

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
│   │   ├── feed/                  # Shorts 스타일 피드
│   │   ├── explore/               # 키워드 검색 화면
│   │   ├── profile/               # 프로필 + 학습 스트릭
│   │   └── common/                # 공유 위젯 (VideoListTile)
│   └── main.dart
├── docs/                          # setup/deploy/testing/architecture
├── .planning/decisions/           # ADR 0001~0005
├── AGENTS.md · BONUS.md
└── android/
```

---

## 🚀 실행 방법

### 사전 준비
1. Flutter SDK 3.10+
2. Firebase 프로젝트 + `google-services.json`
3. **YouTube Data API v3 Key** 발급 (Google Cloud Console)
   - `GEMINI_API_KEY`는 현재 미사용 — 비워도 동작

### 빌드 & 설치
```bash
# 의존성 설치
flutter pub get

# 디버그 빌드 (BlueStacks 등)
flutter build apk --debug --dart-define=YOUTUBE_API_KEY=<your_youtube_key>

# 한글 경로 우회로 APK는 아래 경로에 생성됨
adb install -r C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk
```

> 자세한 절차는 [`docs/setup.md`](docs/setup.md) / [`docs/deploy.md`](docs/deploy.md) 참조.

> 한글 경로에서 빌드 시 `impellerc.exe` 크래시가 발생할 수 있어 `android/app/build.gradle.kts`에서 `buildDirectory`를 `C:/temp/...`로 리다이렉트합니다.

---

## 📋 진행 현황

### ✅ 완료
- **Task 1**: Flutter 프로젝트 초기 세팅, Firebase 연동
- **Task 2**: Firebase Auth + Google 로그인 기반 구조
- **Task 3**: 온보딩 — 관심사 선택 UI (Wrap chip + 3개 이상 검증)
- **Task 6.5**: **YouTube Shorts 피드** + Firestore 영구 캐싱
  - (Phase 1의 Gemini 생성 카드 → YouTube 영상 피드로 전환, 데드코드 정리 — [ADR-0004](.planning/decisions/ADR-0004-youtube-shorts-pivot.md))
- **Task 8**: 탐색/검색 화면 (키워드 YouTube 검색)
- **Task 9**: 프로필 화면 + 학습 스트릭 (결정적 테스트 포함)
- **Task 10**: 문서화 (setup/deploy/testing/architecture + ADR 5건 + AGENTS/BONUS)

### 🔜 남은 과제
- Firestore 보안 규칙 강화 (현재 테스트 모드)
- 자동 integration_test (현재 수동 체크리스트 대체)
- Google 로그인 UI 연결 (현재 `guest` UID 폴백)

---

## 💡 주요 설계 결정 (ADR)

전체 기록: [`.planning/decisions/`](.planning/decisions/)

| ADR | 결정 | 핵심 사유 |
|-----|------|-----------|
| [0001](.planning/decisions/ADR-0001-flutter.md) | Flutter 채택 | 단일 코드베이스 + 세로 피드 구현 용이 |
| [0002](.planning/decisions/ADR-0002-firebase.md) | Firebase Auth + Firestore | 서버리스, 사용자별 문서 모델 |
| [0003](.planning/decisions/ADR-0003-no-cloud-functions.md) | Cloud Functions 미사용 | Blaze 유료 회피, 클라이언트 직접 호출 |
| [0004](.planning/decisions/ADR-0004-youtube-shorts-pivot.md) | Gemini 카드 → YouTube 피드 | Gemini 무료 토큰 한도, 컨셉 정합성 |
| [0005](.planning/decisions/ADR-0005-url-launcher-vs-webview.md) | WebView 대신 url_launcher | webview_flutter AGP 비호환, 안정성 |

상세 문서: [setup](docs/setup.md) · [deploy](docs/deploy.md) · [testing](docs/testing.md) · [architecture](docs/architecture.md) · [AGENTS](AGENTS.md) · [BONUS](BONUS.md)

---

## 🛠 개발 워크플로우

이 프로젝트는 **superpowers 워크플로우**로 개발됩니다:

1. **brainstorming** — 기능 설계 탐색
2. **writing-plans** — TDD 기반 단계별 구현 플랜 작성 (`docs/superpowers/plans/`)
3. **executing-plans** — 플랜에 따라 작은 단위로 구현 + 커밋
4. **systematic-debugging** — 버그 발생 시 가설 검증 기반 접근

---

## 📄 라이선스

학습용 프로젝트 (경희대학교 클라우드 캡스톤)

---

**Made with Claude Code 🤖**
