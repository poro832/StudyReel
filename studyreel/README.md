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
| **콘텐츠 API** | YouTube Data API v3, Google Gemini API |
| **외부 실행** | url_launcher (YouTube 앱 연동) |
| **테스트** | mocktail, fake_cloud_firestore, firebase_auth_mocks |

---

## 🗂 프로젝트 구조

```
studyreel/
├── lib/
│   ├── core/                      # 테마, 라우터
│   ├── data/
│   │   ├── models/                # StudyCard, YoutubeVideo
│   │   ├── repositories/          # CardRepository, YoutubeRepository
│   │   └── services/              # ClaudeService, YoutubeService
│   ├── domain/                    # Riverpod 프로바이더
│   ├── presentation/
│   │   ├── onboarding/            # 관심사 선택 화면
│   │   ├── feed/                  # Shorts 스타일 피드
│   │   ├── detail/                # 카드 상세 + 퀴즈
│   │   └── profile/               # 프로필 + 학습 통계
│   └── main.dart
├── docs/
│   └── superpowers/
│       ├── specs/                 # 설계 문서
│       └── plans/                 # 구현 플랜
└── android/
```

---

## 🚀 실행 방법

### 사전 준비
1. Flutter SDK 3.10+
2. Firebase 프로젝트 + `google-services.json`
3. API 키 두 개 발급:
   - **Gemini API Key** (Google AI Studio)
   - **YouTube Data API v3 Key** (Google Cloud Console)

### 빌드 & 설치
```bash
# 의존성 설치
flutter pub get

# 디버그 빌드 (BlueStacks 등)
flutter build apk --debug \
  --dart-define=GEMINI_API_KEY=<your_gemini_key> \
  --dart-define=YOUTUBE_API_KEY=<your_youtube_key>

# 에뮬레이터에 설치
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

> 한글 경로에서 빌드 시 `impellerc.exe` 크래시가 발생할 수 있어 `android/app/build.gradle.kts`에서 `buildDirectory`를 `C:/temp/...`로 리다이렉트합니다.

---

## 📋 진행 현황

### ✅ 완료
- **Task 1**: Flutter 프로젝트 초기 세팅, Firebase 연동
- **Task 2**: Firebase Auth + Google 로그인 기반 구조
- **Task 3**: 온보딩 — 관심사 선택 UI (Wrap chip + 3개 이상 검증)
- **Task 4**: AI 카드 생성 — Gemini API 직접 호출 (Cloud Functions 대체로 무료화)
- **Task 5**: Firestore 카드 모델 + Repository (Quiz 포함)
- **Task 6**: 메인 피드 UI (PageView 세로 스와이프 + 북마크)
- **🆕 Task 6.5**: **YouTube Shorts 피드 전환** + Firestore 캐싱

### 🔜 진행 예정
- Task 7: 카드 상세 화면 + 퀴즈 위젯
- Task 8: 탐색/검색 화면
- Task 9: 프로필 + 학습 스트릭 + E2E 테스트
- Task 10: 문서화 (ADR, AGENTS.md, BONUS.md)

---

## 💡 주요 설계 결정

### 1. Cloud Functions → Gemini API 직접 호출
- **이유**: Cloud Functions는 Firebase Blaze(유료) 플랜 필수
- **대안**: 클라이언트에서 Gemini API 직접 호출 (`--dart-define`으로 키 주입)
- **트레이드오프**: 키가 APK에 포함됨 → 학습용 프로젝트에서 수용 가능

### 2. WebView 임베드 → url_launcher 외부 실행
- **이유**: `youtube_player_iframe`이 의존하는 `webview_flutter_android 2.x`가 최신 AGP와 호환 안 됨
- **대안**: 썸네일 표시 + 탭 시 YouTube 앱 외부 실행
- **장점**: 네이티브 YouTube UX, 의존성 단순화, BlueStacks에서도 안정 동작

### 3. Firestore 캐싱 적극 활용
- **이유**: YouTube Data API 무료 쿼터 10,000 units/일 (search = 100 units/회)
- **전략**: 첫 검색 결과를 Firestore에 영구 저장 → 재실행 시 API 호출 없이 로드

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
