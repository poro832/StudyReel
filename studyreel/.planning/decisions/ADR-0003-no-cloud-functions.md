# ADR-0003: Cloud Functions 미사용 — 클라이언트 직접 API 호출

- 상태: 채택됨
- 일자: 2026-04-28
- 대체: 초기 설계의 "Cloud Functions + Claude API" 방안

## 맥락

초기 설계는 Cloud Functions에서 Claude API를 호출해 학습 카드를 생성하는 구조였다.
그러나 **Cloud Functions는 Firebase Blaze(종량 과금) 플랜이 필수**이고,
캡스톤은 무료 범위로 진행해야 한다.

## 결정

Cloud Functions를 사용하지 않고, **외부 API를 클라이언트(Flutter)에서 직접 호출**한다.
API 키는 빌드 시 `--dart-define`으로 주입한다.

## 근거

- Blaze 플랜 결제 회피 (무료 범위 유지)
- 호출 경로 단순화 (서버 홉 제거)
- 학습용 프로젝트 — 키 노출 리스크를 수용 가능한 트레이드오프로 판단

## 트레이드오프 / 리스크

- API 키가 APK에 포함됨 → 운영 앱이라면 부적절. 학습 범위에서만 허용
- 레이트리밋/쿼터를 클라이언트가 직접 감내 → 재시도·캐싱으로 완화
  - Gemini 429 → 지수 백오프 재시도
  - YouTube 403(쿼터) → Firestore 영구 캐싱 ([ADR-0004](./ADR-0004-youtube-shorts-pivot.md))

## 결과

`pubspec.yaml`에서 `cloud_functions` 의존성 제거. 외부 호출은 `http` 패키지로 일원화.
