# YouTube Shorts 피드 전환 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gemini AI 카드 피드를 YouTube Shorts/Reels 스타일의 전체 화면 세로 영상 피드로 전환한다.

**Architecture:** YouTube Data API v3로 주제별 교육 영상을 검색하고 `youtube_player_iframe` 패키지로 전체 화면 세로 PageView에 임베딩한다. 기존 Gemini 카드 구조(StudyCard, CardRepository)는 건드리지 않고, YouTube 전용 모델·서비스·프로바이더를 새로 추가한다. FeedScreen만 교체한다.

**Tech Stack:** youtube_player_iframe ^3.0.2, YouTube Data API v3, Riverpod FutureProvider, Flutter PageView

---

## 사전 준비 — YouTube API 키 발급

> 구현 전 반드시 완료해야 한다.

- [ ] Google Cloud Console(console.cloud.google.com) → 프로젝트 선택(studyreel-53c70)
- [ ] API 및 서비스 → 라이브러리 → "YouTube Data API v3" 검색 → 사용 설정
- [ ] API 및 서비스 → 사용자 인증 정보 → API 키 생성
- [ ] 키 값을 별도로 메모해둔다 (`YOUTUBE_API_KEY` 환경변수로 사용)

---

## 파일 구조

```
lib/
  data/
    models/
      youtube_video.dart          # 신규 — YoutubeVideo 모델
    services/
      youtube_service.dart        # 신규 — YouTube Data API 검색
  domain/
    youtube_provider.dart         # 신규 — FutureProvider
  presentation/
    feed/
      feed_screen.dart            # 수정 — Shorts PageView 피드
      shorts_widget.dart          # 신규 — 전체 화면 플레이어 위젯
pubspec.yaml                      # 수정 — youtube_player_iframe 추가
android/app/src/main/AndroidManifest.xml  # 수정 — cleartext 허용
```

---

## Task 1: 패키지 추가 & Android 설정

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: pubspec.yaml에 패키지 추가**

`dependencies:` 블록 안 `http: ^1.2.0` 아래에 추가:

```yaml
  youtube_player_iframe: ^3.0.2
```

- [ ] **Step 2: 패키지 설치**

```bash
cd studyreel
flutter pub get
```

Expected: `Got dependencies!` 출력, 오류 없음

- [ ] **Step 3: AndroidManifest.xml — cleartext 트래픽 허용**

`<application` 태그에 속성 추가 (YouTube 임베드는 http 리소스를 요청함):

```xml
<application
    android:label="studyreel"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
```

- [ ] **Step 4: 변경사항 확인**

```bash
grep -n "youtube_player_iframe" pubspec.yaml
grep -n "usesCleartextTraffic" android/app/src/main/AndroidManifest.xml
```

Expected: 각각 1줄 출력

---

## Task 2: YoutubeVideo 모델 + YoutubeService

**Files:**
- Create: `lib/data/models/youtube_video.dart`
- Create: `lib/data/services/youtube_service.dart`

- [ ] **Step 1: YoutubeVideo 모델 작성**

`lib/data/models/youtube_video.dart`:

```dart
class YoutubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String topic;
  final String thumbnailUrl;
  final bool isBookmarked;

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.topic,
    required this.thumbnailUrl,
    this.isBookmarked = false,
  });

  YoutubeVideo copyWith({bool? isBookmarked}) => YoutubeVideo(
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        topic: topic,
        thumbnailUrl: thumbnailUrl,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}
```

- [ ] **Step 2: YoutubeService 작성**

`lib/data/services/youtube_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

const _ytApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const _searchEndpoint = 'https://www.googleapis.com/youtube/v3/search';

class YoutubeService {
  Future<List<YoutubeVideo>> searchShorts(List<String> topics) async {
    final videos = <YoutubeVideo>[];

    for (final topic in topics) {
      final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
        'part': 'snippet',
        'q': '$topic 학습 쇼츠',
        'type': 'video',
        'videoDuration': 'short',
        'maxResults': '3',
        'relevanceLanguage': 'ko',
        'regionCode': 'KR',
        'key': _ytApiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('YouTube API 오류: ${response.statusCode}');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final items = body['items'] as List;

      for (final item in items) {
        final id = item['id']['videoId'] as String?;
        if (id == null) continue;
        final snippet = item['snippet'] as Map<String, dynamic>;
        videos.add(YoutubeVideo(
          videoId: id,
          title: snippet['title'] as String,
          channelTitle: snippet['channelTitle'] as String,
          topic: topic,
          thumbnailUrl:
              snippet['thumbnails']['high']['url'] as String,
        ));
      }
    }

    return videos;
  }
}
```

- [ ] **Step 3: 컴파일 확인**

```bash
flutter analyze lib/data/models/youtube_video.dart lib/data/services/youtube_service.dart
```

Expected: `No issues found!`

---

## Task 3: youtube_provider (Riverpod)

**Files:**
- Create: `lib/domain/youtube_provider.dart`

- [ ] **Step 1: youtube_provider.dart 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/youtube_video.dart';
import '../data/services/youtube_service.dart';

final youtubeServiceProvider = Provider<YoutubeService>((_) => YoutubeService());

// 피드 내 로컬 북마크 상태 관리용
final youtubeVideosProvider =
    StateProvider<List<YoutubeVideo>>((_) => []);

final youtubeFeedProvider =
    FutureProvider.family<List<YoutubeVideo>, List<String>>(
  (ref, topics) async {
    final service = ref.read(youtubeServiceProvider);
    final videos = await service.searchShorts(topics);
    ref.read(youtubeVideosProvider.notifier).state = videos;
    return videos;
  },
);
```

- [ ] **Step 2: 컴파일 확인**

```bash
flutter analyze lib/domain/youtube_provider.dart
```

Expected: `No issues found!`

---

## Task 4: ShortsWidget — 전체 화면 YouTube 플레이어

**Files:**
- Create: `lib/presentation/feed/shorts_widget.dart`

- [ ] **Step 1: shorts_widget.dart 작성**

```dart
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../data/models/youtube_video.dart';

class ShortsWidget extends StatefulWidget {
  final YoutubeVideo video;
  final bool isActive;
  final VoidCallback onBookmark;

  const ShortsWidget({
    super.key,
    required this.video,
    required this.isActive,
    required this.onBookmark,
  });

  @override
  State<ShortsWidget> createState() => _ShortsWidgetState();
}

class _ShortsWidgetState extends State<ShortsWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoId,
      autoPlay: widget.isActive,
      params: const YoutubePlayerParams(
        showFullscreenButton: false,
        showVideoAnnotations: false,
        mute: false,
        loop: true,
      ),
    );
  }

  @override
  void didUpdateWidget(ShortsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.playVideo();
      } else {
        _controller.pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 전체 화면 YouTube 플레이어
        YoutubePlayer(controller: _controller),

        // 하단 정보 오버레이
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(widget.video.topic,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                      const SizedBox(height: 4),
                      Text(widget.video.channelTitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 북마크 버튼
                GestureDetector(
                  onTap: widget.onBookmark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.video.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: widget.video.isBookmarked
                            ? kPrimaryColor
                            : Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.video.isBookmarked ? '저장됨' : '저장',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
flutter analyze lib/presentation/feed/shorts_widget.dart
```

Expected: `No issues found!`

---

## Task 5: FeedScreen 교체

**Files:**
- Modify: `lib/presentation/feed/feed_screen.dart`

- [ ] **Step 1: feed_screen.dart 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/youtube_video.dart';
import '../../domain/topic_provider.dart';
import '../../domain/youtube_provider.dart';
import 'shorts_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(selectedTopicsProvider).toList();
    final videosAsync = ref.watch(youtubeFeedProvider(topics));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(width: 20),
            const Text('탐색',
                style: TextStyle(fontSize: 16, color: kTextGray)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: kPrimaryColor,
                child: Text('나',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
      body: videosAsync.when(
        data: (fetchedVideos) {
          final videos = ref.watch(youtubeVideosProvider);
          final list = videos.isEmpty ? fetchedVideos : videos;

          if (videos.isEmpty && fetchedVideos.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(youtubeVideosProvider.notifier).state = fetchedVideos;
            });
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => ShortsWidget(
              video: list[index],
              isActive: index == _currentIndex,
              onBookmark: () {
                final updated = list[index]
                    .copyWith(isBookmarked: !list[index].isBookmarked);
                final newList = [...list];
                newList[index] = updated;
                ref.read(youtubeVideosProvider.notifier).state = newList;
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('영상을 불러오지 못했습니다.',
                  style: TextStyle(color: kTextGray)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(youtubeFeedProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 & BlueStacks 설치**

```bash
flutter build apk --debug \
  --dart-define=GEMINI_API_KEY=AIzaSyBGSQ04e2V3aJs5x81Ql8NEALUjHeA4p7Q \
  --dart-define=YOUTUBE_API_KEY=<발급받은_키>
```

```bash
copy C:\temp\studyreel_build\app\outputs\flutter-apk\app-debug.apk C:\temp\app-debug.apk
adb -s 127.0.0.1:5555 install -r C:\temp\app-debug.apk
```

- [ ] **Step 3: 동작 확인 체크리스트**
  - 온보딩 → 토픽 3개 선택 → 시작하기
  - 피드 진입 시 첫 번째 YouTube 영상 자동 재생
  - 위로 스크롤 시 다음 영상으로 전환, 이전 영상 일시정지
  - 하단 오버레이에 주제 태그 / 제목 / 채널명 표시
  - 북마크 아이콘 탭 → 색상 변경 확인

- [ ] **Step 4: 커밋**

```bash
git add lib/data/models/youtube_video.dart \
        lib/data/services/youtube_service.dart \
        lib/domain/youtube_provider.dart \
        lib/presentation/feed/shorts_widget.dart \
        lib/presentation/feed/feed_screen.dart \
        pubspec.yaml \
        android/app/src/main/AndroidManifest.xml
git commit -m "feat: YouTube Shorts 스타일 피드로 전환"
```
