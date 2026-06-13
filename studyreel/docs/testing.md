# 테스트 가이드

## 전체 실행

```bash
cd studyreel
flutter test
```

현재 **54개 테스트** 통과 (단위·위젯 + E2E 플로우, 회귀 가드).
매 푸시/PR마다 GitHub Actions가 `flutter analyze`(0건) + `flutter test`를 자동 실행한다
([워크플로우](../../.github/workflows/flutter.yml)).

## 테스트 구성

| 파일 | 대상 | 검증 내용 |
|------|------|-----------|
| `test/repositories/auth_repository_test.dart` | AuthRepository | Google 로그인/로그아웃 |
| `test/repositories/youtube_repository_test.dart` | YoutubeRepository | 캐시 저장/로드, 북마크 필터 |
| `test/repositories/streak_repository_test.dart` | StreakRepository | 스트릭 날짜 로직 (첫방문/연속/리셋) |
| `test/domain/topic_provider_test.dart` | TopicNotifier | 관심사 선택/검증 |
| `test/widget_test.dart` | 앱 부팅 | 온보딩 화면 표시 |

## 테스트 전략

- **Firestore**: `fake_cloud_firestore` 로 인메모리 가짜 DB 사용 (네트워크 불필요)
- **Auth**: `firebase_auth_mocks` 의 `MockFirebaseAuth(signedIn: true)`
- **시간 의존 로직**: `StreakRepository`는 `now` 콜백을 주입받아 날짜 시나리오를 결정적으로 테스트
- **외부 API**: YouTube/네트워크 호출 계층(`YoutubeService`)은 단위 테스트에서 제외 (Repository가 경계)

## 개별 실행

```bash
flutter test test/repositories/streak_repository_test.dart
```

## E2E 플로우 (헤드리스)

`test/integration/feed_flow_test.dart` — 실제 앱 위젯 트리 + go_router 라우팅 +
여러 화면 전환 + Firestore 영속을 헤드리스로 검증하는 통합(E2E) 테스트.
네트워크/WebView는 가짜 서비스로 대체해 흐름에 집중한다:

- 로그인 사용자 + 토픽 없음 → **온보딩** 라우팅
- 관심 토픽 3개 선택 → "시작하기" → **홈 피드** 진입
- 저장한 토픽이 Firestore에 **영속**됐는지 확인

기기 레벨(실제 WebView 재생)은 아래 수동 체크리스트로 보완합니다:

- 온보딩 → 관심사 3개 선택 → 시작하기
- 피드 진입 → YouTube 썸네일 표시 → 탭 시 외부 실행
- 상단 "탐색" → 키워드 검색 → 결과 리스트
- 아바타 → 프로필 → 스트릭 카드 + 저장한 영상
- 북마크 토글 → 프로필에 반영
