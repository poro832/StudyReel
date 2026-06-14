---
marp: true
theme: default
paginate: true
style: |
  section { font-size: 26px; }
  h1 { color: #6C3CE9; }
  h2 { color: #6C3CE9; font-size: 34px; }
  table { font-size: 21px; }
  blockquote { border-left: 5px solid #6C3CE9; font-style: normal; }
  .small { font-size: 19px; color: #666; }
---

<!-- _class: lead -->

# 📚 StudyReel
## 기말 발표 — "스크롤 중독을 학습 습관으로"

**YouTube Shorts를 교육용 피드로 바꾼 인앱 학습 앱**

이동찬 · 2026-06 · 클라우드 캡스톤

<span class="small">GitHub: github.com/poro832/StudyReel · 데모 APK: poro832.github.io/studyreel-final/app</span>

---

## 1. 비전 (Vision)

> ### "틱톡에 뺏기던 30분을, 그대로 학습 30분으로."

- 사람들은 이미 **세로 피드 + 자동재생**에 길들여져 있습니다
- 그 **소비 습관은 그대로 두고, 콘텐츠만 교육으로** 바꾸면?
- StudyReel = **알고리즘에 휘둘리지 않는, 내가 고른 토픽만 흐르는 학습 피드**

---

## 2. 문제 정의 (Problem)

**"공부하려고 유튜브를 켰는데, 5분 뒤엔 예능을 보고 있다."**

| 기존 방식 | 한계 |
|---|---|
| YouTube 직접 검색 | 알고리즘이 오락 영상으로 이탈 유도 |
| 인강 플랫폼 | 긴 호흡 — 자투리 시간에 부적합 |
| Shorts 학습 채널 | 구독해도 피드에 예능이 섞임 |

→ 필요한 것: **이탈 경로가 차단된, 학습 전용 숏폼 피드**

---

## 3. 프로젝트 계획 — WBS & 기술 스택

**WBS** (MoSCoW 우선순위, 진행 현황: poro832.github.io/studyreel-final/wbs.html)

- **Must**: 온보딩(토픽 선택) → 인앱 Shorts 피드 → 북마크/저장 ✅
- **Should**: 탐색 검색 · 프로필 · 학습 스트릭 · 로그인 ✅
- **Could**: 무한 스크롤 · 시청 기록 · 학습 수준 선택 · 다크 테마 ✅

**기술 스택**

| 영역 | 기술 | 근거 |
|---|---|---|
| 프레임워크 | Flutter 3.35 | ADR-0001 |
| 상태관리 | Riverpod | 단방향 데이터 흐름 |
| 백엔드 | Firebase Auth + Firestore | ADR-0002/0003 |
| 콘텐츠 | YouTube Data API v3 + youtube_player_iframe | ADR-0004/0005 |

---

## 4. 프로젝트 진행 및 완료

```
4월          5월                         6월
계획·설계 → Gemini 카드 MVP → [피벗] → Shorts 피드 → error 152 돌파
                ADR-0004                              ↓
                                  로그인·시청기록·무한스크롤·보안규칙 → 완료
```

- 커밋 **67건** · ADR **5건** · 데드코드 7파일 청산(피벗 시)
- Must/Should/Could **전 항목 완료** — 릴리스 APK 배포 중
- 피벗 근거: Gemini 무료 토큰 한도 실측 → **데이터로 방향 전환** (ADR-0004)

---

## 5. 어떻게 구현했나 — 아키텍처 & 앱 구조

```
presentation/ (Flutter UI)  ── watch ──▶  domain/ (Riverpod Provider)
                                              │ ref.read
                                              ▼
                              data/repositories (캐싱 정책의 단일 경계)
                                  ├─ data/services  (YouTube Data API)
                                  └─ Firestore      (캐시·북마크·스트릭·시청기록)
```

- **단방향 의존**: UI는 Provider만, Provider는 Repository만 안다
- Repository = **"Firestore 캐시 우선, 없으면 API"** 정책의 단일 지점
- 디렉토리: `core / data(models·repositories·services) / domain / presentation`

---

## 6. 구현 시행착오 — `error 152` 돌파

**증상**: Shorts 인앱 임베드 시 전부 `error 152-4` — API는 `embeddable: true`라고 거짓말

| 가설 | 검증 | 결과 |
|---|---|---|
| WebView가 영상 합성 불가 | 실기기에서 에러 UI가 또렷이 렌더됨 | ❌ 폐기 |
| autoplay 정책 차단 | 152 해결 후 소리 자동재생 정상 | ❌ 폐기 |
| **Shorts 임베드 정책** | 채널 다른 3개 영상 전부 152 | ✅ 규명 |

**해결**: 라이브러리 소스에서 `origin`이 `host`로도 쓰임을 발견
→ 호스트를 **`youtube-nocookie.com`으로 교체** → 실기기(Z Fold7) 재생 검증 ✅

---

## 7. 성능 최적화 & 코드 품질

**성능 최적화**
- YouTube API 쿼터(10k/day) 보호 — **Firestore 영구 캐싱** → 재방문 API 호출 0회
- Gemini 429 → **지수 백오프**(10→20→40s) · 재생불가 영상 **3초 워치독 자동 스킵**
- 시청한 영상 제외 + `pageToken` 무한 스크롤로 **중복 노출 원천 차단**

**코드 품질 관리**
- `flutter analyze` **에러/경고 0건** 유지 (AGENTS.md에 게이트로 명문화)
- DRY: `youtube_launcher` · `VideoListTile` 공통화, 피벗 후 데드코드 즉시 제거
- 한국어 컨벤션 커밋(`feat:`/`fix:`/`docs:`) — 그린 상태에서만 커밋

---

## 8. 테스트 — 단위 + 통합

| 종류 | 도구 | 개수 | 대상 |
|---|---|---|---|
| **단위·위젯·E2E** | flutter_test + fake_cloud_firestore + firebase_auth_mocks | **57개** | 캐시·북마크·스트릭·중복제거·토픽·서비스 필터 |
| **통합 테스트** | @firebase/rules-unit-testing (에뮬레이터) | **4개** | Firestore 보안 규칙 — 내 데이터만 읽기/쓰기 |

- 시간 의존 로직(스트릭)은 `now` 콜백 주입 → **결정적 테스트**
- 무한 스크롤 중복제거는 순수 함수 `dedupeAppend`로 분리 → TDD
- 상세: `docs/testing.md`

---

## 9. 개발 환경 · 빌드 · 배포

| 단계 | 내용 | 문서 |
|---|---|---|
| **환경 설정** | Flutter SDK → `flutter pub get` → API 키 2종 발급 → `flutterfire configure` | `docs/setup.md` |
| **빌드** | `flutter build apk --release --dart-define=YOUTUBE_API_KEY=…` (키는 빌드타임 주입, 소스에 없음) | `docs/deploy.md` |
| **배포** | APK → GitHub Pages 호스팅 + `adb install` (Cloud Functions 미사용 = 서버 배포 없음, ADR-0003) | `docs/deploy.md` |

- **설치 가이드**: GitHub README — 소개 페이지 · APK 다운로드 링크 · 5분 셋업
- 트러블슈팅 문서화: 한글 경로 `impellerc` 크래시 → `buildDirectory` 리다이렉트

---

## 10. ADR 요약 — 질의응답 준비

| ADR | 결정 | 핵심 사유 |
|---|---|---|
| **0001** | Flutter 채택 | 단일 코드베이스, 세로 피드 구현 용이 |
| **0002** | Firebase Auth + Firestore | 서버리스, 사용자별 문서 모델 |
| **0003** | Cloud Functions 미사용 | Blaze 과금 회피 → 클라이언트 직접 호출 + 캐싱 |
| **0004** | Gemini 카드 → Shorts 피드 피벗 | 토큰 한도 실측 데이터 기반 전환 |
| **0005** | url_launcher → (재검토) 인앱 iframe | "인앱이 안 되면 컨셉이 죽는다" |

> 모든 기술 질문은 ADR 문서 기준으로 답변합니다 — `.planning/decisions/`

---

## 11. AI Agent 워크플로우 — 가산점

**① AI Agent / 스킬 / 워크플로우 적극 활용**
- Claude Code + superpowers 스킬: brainstorming → writing-plans → executing-plans(TDD) → systematic-debugging
- 막히면 GPT·Gemini 교차검증 — `youtube-nocookie` 해법도 외부 제안 → 소스 검증 → 실기기 확인으로 채택

**② 본인만의 기법 — "단일 헌법 파일 + 증거 기반 종결"**
- **AGENTS.md 한 파일**에 빌드 게이트·아키텍처 불변식·캐싱 정책·테스트 규칙·커밋 규약 통합
  → 어떤 에이전트(Claude/Codex)든 같은 규칙으로 작업
- AI 출력은 항상 **화면·로그·테스트로 끝을 본다** (오진 2건을 실측으로 폐기)

**③ LLM Wiki 암묵지 운영**
- ADR(결정) + 트러블슈팅 블로그(152 전 과정) + AGENTS.md(규칙) = **LLM이 읽고 일하는 지식 베이스** — 새 세션의 에이전트도 즉시 맥락 복원

---

## 12. 🎬 시연 데모 (30초)

**사용자 시나리오: "출근길 5분, 앱 하나로 학습"**

1. **로그인 → 온보딩** — 관심 토픽 3개 + 학습 수준(중등/고등/대학) 선택
2. **피드** — 교육 Shorts가 **소리와 함께 인앱 자동재생**, 스와이프 → 다음 영상
3. **북마크 ⭐ + 무한 스크롤** — 끝까지 내려도 새 영상, 본 영상은 다시 안 나옴
4. **프로필** — 🔥 학습 스트릭 · 저장한 영상 · 최근 본 영상

> 임팩트 포인트: **"유튜브가 막아둔 Shorts가, 우리 앱 안에서 소리내며 재생되는 순간"**

---

## 13. 활용 방안 · 향후 발전

**어떻게 활용할 것인가**
- 자투리 시간(통학·휴식) **마이크로러닝** — 토픽·수준 맞춤 피드
- 교육기관: 과목별 큐레이션 피드로 확장 가능 (Firestore 토픽 모델 그대로 활용)

**향후 발전 방향**
- 시청 기록 기반 **개인화 추천** · 학습 퀴즈(Gemini 요약 확장 — 키 슬롯 이미 준비)
- 자동 integration_test 도입, iOS 지원

> ### StudyReel — 스크롤 중독을 학습 습관으로. 감사합니다.

<span class="small">github.com/poro832/StudyReel · APK: poro832.github.io/studyreel-final/app</span>

---

<!-- 이하 백업 슬라이드: Q&A에서 호출 시에만 -->

# 백업 슬라이드 (Q&A용)

---

## B1. 앱 구조 — 디렉토리 상세

```
studyreel/
├── lib/
│   ├── core/            # 테마, go_router 라우터, youtube_launcher
│   ├── data/
│   │   ├── models/        # YoutubeVideo
│   │   ├── repositories/  # Youtube / Streak / Auth / Topic
│   │   └── services/      # YoutubeService (API 원시 호출)
│   ├── domain/          # Riverpod Provider 6종
│   └── presentation/    # onboarding / feed / explore / profile / common
├── test/                # 단위·위젯·E2E 57개
├── firestore-tests/     # 보안 규칙 통합 테스트 4개
├── docs/                # setup / deploy / testing / architecture / blog
└── .planning/decisions/ # ADR 0001~0005
```

---

## B2. 데이터 흐름 (피드)

```
FeedScreen ─watch→ youtubeFeedProvider ─→ YoutubeRepository
                                            ├─ Firestore 캐시 있음 → 즉시 반환 (API 0회)
                                            └─ 없음 → YouTube search(100 units)
                                                      → 필터(60초↓·교육·재생가능)
                                                      → Firestore 영구 캐시 → 반환
```

- 검색(explore)은 **캐싱 금지** — 임의 쿼리로 Firestore 오염 방지
- 무한 스크롤: `pageToken` 연속 + 시청 id 제외 `dedupeAppend`

---

## B3. 보안 처리

- API 키: 소스 미포함 — `--dart-define` 빌드타임 주입
- Firestore 보안 규칙: **본인 `users/{uid}` 하위만 읽기/쓰기** — 규칙 통합 테스트 4건으로 검증
- google-services.json은 식별자(비밀 아님) — 규칙이 실질 방어선

---

## B4. 성능 측정·수치

- 피드 재진입: API 호출 **0회** (캐시 히트)
- YouTube search 1회 = 100 units → 일 한도 10,000 units 내 설계
- 재생불가 영상: 3초 워치독 → 자동 스킵 (UX 끊김 최소화)
- 테스트: 57 + 통합 4 전체 그린, analyze 경고 0
