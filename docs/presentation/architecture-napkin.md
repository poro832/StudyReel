# StudyReel 아키텍처 — Napkin AI 입력용 텍스트

> 아래 블록 중 하나를 골라 Napkin AI에 붙여넣으면 다이어그램이 생성됩니다.
> (A) 흐름 설명형 — 자동 다이어그램용 / (B) 관계 목록형 — 깔끔한 플로우용 / (C) 계층 구조형

---

## (A) 흐름 설명형 (프로즈)

StudyReel은 교육용 YouTube Shorts를 앱 안에서 세로 피드로 보는 Flutter 모바일 앱이다. 아키텍처는 네 개의 계층으로 나뉜다.

프레젠테이션 계층은 Flutter UI로, 온보딩(토픽 선택) 화면에서 시작해 세로 스와이프 피드로 이어지고, 각 영상은 ShortsWidget의 인앱 플레이어로 재생된다.

상태 관리 계층은 Riverpod이다. 피드 화면은 youtubeFeedProvider(FutureProvider.family)를 구독해 영상 목록을 받는다.

데이터 계층은 Repository와 Service로 구성된다. YoutubeRepository는 캐시 우선 전략을 따른다. 먼저 Cloud Firestore에서 선택한 토픽의 캐시를 읽고, 캐시가 없으면 YoutubeService를 통해 YouTube Data API v3를 호출한다. Service는 search로 영상을 검색한 뒤 videos.list로 임베드 가능 여부와 길이(60초 이하)를 필터링하고, 결과를 다시 Firestore에 캐싱한다.

외부 시스템은 세 가지다. Cloud Firestore는 토픽별 영상 메타데이터와 북마크·학습 스트릭을 저장한다. YouTube Data API v3는 영상 검색과 메타데이터를 제공한다. Firebase Auth는 사용자 식별(게스트 UID 폴백)을 담당한다.

인앱 영상 재생은 YouTube IFrame 플레이어를 youtube-nocookie 호스트로 임베드해 처리한다. API 키는 빌드 타임에 주입되고, 무료 할당량 보호를 위해 Firestore 캐싱을 사용한다.

---

## (B) 관계 목록형 (노드 → 노드)

- 온보딩(토픽 선택) → 피드(세로 스와이프 PageView)
- 피드 → ShortsWidget(인앱 IFrame 플레이어)
- 피드 → youtubeFeedProvider (Riverpod 상태)
- youtubeFeedProvider → YoutubeRepository
- YoutubeRepository → Cloud Firestore : "캐시 우선 읽기"
- YoutubeRepository → YoutubeService : "캐시 미스 시 조회"
- YoutubeService → YouTube Data API v3 : "search + videos.list"
- YoutubeService → Cloud Firestore : "결과 캐싱"
- ShortsWidget → YouTube IFrame(youtube-nocookie) : "인앱 재생"
- Firebase Auth(게스트 UID) → YoutubeRepository : "사용자 식별"

---

## (C) 계층 구조형 (그룹)

**1. 프레젠테이션 (Flutter UI)**
- 온보딩 — 토픽 선택
- 피드 — 세로 스와이프, 자동재생
- ShortsWidget — 인앱 플레이어
- 프로필 — 북마크 · 학습 스트릭

**2. 상태 관리 (Riverpod)**
- youtubeFeedProvider (FutureProvider.family)
- 선택 토픽을 키로 영상 목록 제공

**3. 데이터 (Repository / Service)**
- YoutubeRepository — 캐시 우선 전략, 북마크/스트릭 관리
- YoutubeService — YouTube API 호출 + 60초·임베드 필터

**4. 외부 · 클라우드**
- Cloud Firestore — 토픽별 캐시 · 북마크 · 스트릭
- YouTube Data API v3 — 영상 검색/메타데이터
- Firebase Auth — 게스트 UID
- YouTube IFrame (youtube-nocookie) — 인앱 재생

---

## 핵심 데이터 흐름 한 줄 요약

토픽 선택 → Provider 요청 → Repository(Firestore 캐시 우선) → 미스 시 Service가 YouTube API 호출·필터링 → Firestore 캐싱 → 피드에 표시 → youtube-nocookie로 인앱 재생
