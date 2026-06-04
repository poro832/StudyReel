# StudyReel — 무한 스크롤 · 시청 기록 설계

> 2026-06-04 · WBS: "무한 스크롤 · 시청 기록 (COULD)"

## 목표
피드 끝에서 다음 묶음을 자동 로딩(무한 스크롤)하고, 사용자가 실제로 본 영상을
기록해 프로필에 보여주며 중복 노출을 막는다.

## 결정 사항
- **무한 스크롤 방식**: YouTube `pageToken`으로 같은 쿼리의 다음 페이지를 이어받아
  한 세션 내 중복을 원천 차단한다.
- **"봤다" 기준**: 영상이 실제 재생(`PlayerState.playing`)에 도달하면 시청으로 기록.
  (재생 실패·스킵 영상은 기록되지 않음 — 워치독이 이미 playing을 감지 중)

## 1. 시청 기록 (Watch History)
- **저장소**: Firestore `users/{uid}/watch_history/{videoId}`
  - 필드: videoId, title, channelTitle, topic, thumbnailUrl, `watchedAt`(ms epoch)
  - 재시청 시 `watchedAt` 갱신(최근 본 순 정렬 유지)
- **기록 경로**: `ShortsWidget`이 playing 도달 시 `onWatched(video)` 1회 호출 →
  `feed_screen`이 `repo.recordWatched(video)` 호출 + 메모리 `_watchedIds`에 추가
- **표시**: 프로필에 "최근 본 영상" 섹션(최근 30개, watchedAt desc, `VideoListTile` 재사용)
- **중복 제거**: 피드 시작 시 `repo.loadWatchedIds()`로 시청 집합 로드 →
  새 페이지 append 시 시청한 videoId 제외

## 2. 무한 스크롤 (page token)
- **서비스**: `searchTopicPage(topic, {pageToken, suffix})` →
  `(List<YoutubeVideo> videos, String? nextPageToken)`
  - 기존 필터 재사용: 임베드 가능 · 60초 이하 · 교육 적합(`isEducational`) ·
    재생 가능(`isPlayableInApp`)
- **상태(화면 세션 범위, `_FeedScreenState`)**:
  - `Map<String, String?> _nextToken` (토픽→다음 토큰; 키 없으면 미시작)
  - `Set<String> _exhausted` (토큰 소진 토픽)
  - `bool _loadingMore`, `Set<String> _watchedIds`
- **트리거**: `onPageChanged(i)`에서 `i >= list.length - 2 && !_loadingMore`면 `_loadMore()`
- **_loadMore()**: 소진되지 않은 토픽마다 `searchTopicPage(topic, pageToken: _nextToken[topic])`
  호출 → (현재 리스트 id + `_watchedIds`) 중복 제외 → 리스트 append →
  nextToken 저장(null이면 `_exhausted`에 추가)
- **첫 _loadMore**: 토큰이 없으므로 fresh 검색(page 1, 새 무작위 접미사)으로 시작,
  이후 토큰으로 연속. 초기 캐시 영상과 겹치면 중복 제거가 걸러냄.

## 3. 순수 로직 분리 & 테스트 (TDD)
- 순수 함수 `dedupeAppend(existing, incoming, {excludedIds})` →
  중복/제외 id를 뺀 새 리스트 (단위 테스트)
- repo (fake_cloud_firestore):
  - `recordWatched` 저장 + `loadWatchHistory` watchedAt desc 정렬
  - `loadWatchedIds` 집합 반환
- 실기기: 끝까지 스크롤 → 새 영상 로딩, 프로필 "최근 본 영상" 표시 확인

## 범위 밖 (YAGNI)
시청 진행률 저장 · 이어보기 · 기록 삭제 UI · 토픽별 무한 균등 분배.
