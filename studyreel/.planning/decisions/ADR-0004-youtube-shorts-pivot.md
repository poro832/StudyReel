# ADR-0004: Gemini AI 카드 피드 → YouTube Shorts 피드 전환

- 상태: 채택됨
- 일자: 2026-04-29
- 대체: 초기의 "Gemini 생성 학습 카드 피드" (Phase 1)

## 맥락

Phase 1에서 Gemini API로 학습 카드(제목/요약/포인트/퀴즈)를 생성해 피드에 표시했다.
실사용 테스트 중 다음 문제가 반복 발생:

- Gemini 무료 티어 토큰/RPM 한도 → 카드 생성 실패가 잦음
- 카드 1세트 생성에 큰 토큰 소모 → 무료 범위에서 지속 불가

## 결정

피드의 콘텐츠 소스를 **YouTube Data API v3 검색 결과(학습 영상)** 로 전환한다.
Gemini 카드 시스템(`study_card`, `card_repository`, `claude_service`,
`card_provider`, `card_widget`)은 **완전히 제거**한다.

## 근거

- YouTube 무료 쿼터 10,000 units/일 — search 100 units/회로 캡스톤 사용량 충분
- "Shorts/Reels 스타일 학습"이라는 제품 컨셉과 영상 피드가 더 정합적
- 영상 콘텐츠는 토큰 비용 0 (검색만 호출)

## 쿼터 대응

YouTube search 403(쿼터 초과) 방지를 위해 **Firestore 영구 캐싱**:
첫 검색 결과를 `users/{uid}/youtube_videos`에 저장 → 재실행 시 API 호출 0.
키워드 탐색 검색은 임의 쿼리 오염 방지를 위해 비캐시.

## 결과

- 피드 = `ShortsWidget` 썸네일 → 탭 시 YouTube 외부 실행 ([ADR-0005](./ADR-0005-url-launcher-vs-webview.md))
- 인앱 카드 상세 화면 제거 (`/detail` 라우트 삭제)
- 데드코드 7개 파일 삭제, `flutter test` 15건 그린 유지
