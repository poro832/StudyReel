# ADR-0001: 크로스플랫폼 프레임워크로 Flutter 채택

- 상태: 채택됨
- 일자: 2026-04-28

## 맥락

Reels/Shorts 스타일의 세로 스크롤 학습 앱을 단일 코드베이스로 빠르게 만들고,
한 명의 개발자가 짧은 학기 일정 안에 완성해야 한다.

## 결정

**Flutter (Dart)** 를 채택한다. 1차 타깃은 Android.

## 근거

- 단일 코드베이스로 Android/iOS/Web 대응 가능
- `PageView`로 세로 스와이프 피드를 적은 코드로 구현
- Riverpod·go_router 등 성숙한 상태관리/라우팅 생태계
- Firebase 공식 플러그인 지원 (Auth, Firestore)
- 핫 리로드로 UI 반복 개발 속도 확보

## 대안

- **React Native**: 생태계는 크나 네이티브 모듈 설정 부담
- **네이티브(Kotlin)**: iOS 미대응, 개발 속도 불리

## 결과

- `presentation/domain/data` 레이어 구조 확립
- 한글 경로에서 `impellerc` 크래시 → 빌드 출력 ASCII 리다이렉트로 우회 (트레이드오프)
