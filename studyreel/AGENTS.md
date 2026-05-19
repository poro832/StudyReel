# AGENTS.md — 에이전트 운영 헌법

이 저장소에서 작업하는 AI 에이전트가 반드시 지켜야 할 규칙.

## 1. 빌드 / 검증

- 빌드: `flutter build apk --debug --dart-define=YOUTUBE_API_KEY=… --dart-define=GEMINI_API_KEY=…`
- ⚠️ "Gradle build failed to produce an .apk file" 메시지는 **정상**.
  실제 APK는 `C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk`.
  (한글 경로 회피용 buildDirectory 리다이렉트 — `android/app/build.gradle.kts`)
- 완료 주장 전 **반드시** 실행: `flutter analyze lib/ test/` + `flutter test`
- 에러/경고 0건 유지. `info` 레벨 린트는 기존 코드 스타일과 일관되면 허용.

## 2. 아키텍처 불변식

- 레이어 방향: `presentation → domain → data`. 역방향 import 금지.
- UI는 Provider만 watch/read. Firestore/HTTP를 UI에서 직접 호출하지 말 것.
- 외부 API 원시 호출은 `data/services/`, 캐싱·조합 정책은 `data/repositories/`.
- YouTube 외부 실행은 항상 `core/youtube_launcher.dart`의 `launchYoutube()` 사용 (중복 작성 금지).
- explore/profile 영상 타일은 `presentation/common/video_list_tile.dart` 재사용.

## 3. 캐싱 정책 (변경 시 ADR-0004 갱신)

- 피드(`youtubeFeedProvider`): Firestore 캐시 우선, 없을 때만 API 호출.
- 키워드 검색(`searchResultsProvider`): **캐싱 금지** (임의 쿼리로 Firestore 오염 방지).
- 쿼터(YouTube 403 / Gemini 429)는 캐싱·백오프로 완화. 한도 자체를 늘리려 하지 말 것.

## 4. 테스트 규칙

- Firestore → `fake_cloud_firestore`, Auth → `firebase_auth_mocks`.
- 시간 의존 로직은 `now` 콜백 등으로 주입해 결정적으로 테스트 (예: `StreakRepository`).
- 네트워크 호출 계층은 단위 테스트 경계 밖. Repository를 통해 검증.

## 5. 커밋

- 한국어 커밋 메시지. `feat:` / `docs:` / `fix:` 프리픽스.
- 작업 단위로 자주 커밋. 빌드/테스트 그린 상태에서만 커밋.
- 푸시 브랜치: `feature/task-1-setup` (원격 `origin`).
- 커밋 푸터: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`

## 6. 의사결정

- 아키텍처에 영향 주는 변경은 `.planning/decisions/ADR-XXXX-*.md` 추가/갱신.
- 기능 방향이 모호하면 추측해서 구현하지 말고 사용자에게 질문.
- 데드코드는 남기지 말 것 — 제거하고 ADR/문서에 사유 기록.

## 7. 미해결 과제 (인지하고 작업)

- Firestore 보안 규칙이 테스트 모드 — 운영 전 사용자별 강화 필요.
- 자동 integration_test 부재 — 현재 수동 체크리스트(`docs/testing.md`)로 대체.
- Google 로그인 UI 미연결 — 현재 `guest` UID 폴백으로 동작.
