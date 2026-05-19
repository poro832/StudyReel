# ADR-0002: 백엔드로 Firebase (Auth + Firestore) 채택

- 상태: 채택됨
- 일자: 2026-04-28

## 맥락

서버를 직접 운영하지 않고 사용자별 데이터(북마크, 학습 스트릭, 캐시된 영상)를
저장·동기화해야 한다.

## 결정

**Firebase Authentication + Cloud Firestore (Standard, asia-northeast3)** 를 채택한다.
프로젝트: `studyreel-53c70`.

## 근거

- 서버리스 — 인프라 운영 부담 없음
- Firestore 문서 모델이 `users/{uid}/...` 사용자별 컬렉션 구조에 적합
- Flutter 공식 플러그인 + `fake_cloud_firestore`로 테스트 용이
- 무료 Spark 플랜으로 캡스톤 범위 충분

## 데이터 구조

```
users/{uid}/
  youtube_videos/{videoId}   # 피드 캐시 + isBookmarked
  meta/streak                # currentStreak, lastActiveDate
```

비로그인 상태도 동작하도록 `uid` 없으면 `'guest'` 폴백.

## 결과

- 보안 규칙은 현재 테스트 모드 → **운영 전 사용자별 규칙 강화 필요** (미해결 과제)
- Cloud Functions는 의도적으로 미사용 ([ADR-0003](./ADR-0003-no-cloud-functions.md))
