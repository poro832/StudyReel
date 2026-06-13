import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../data/models/youtube_video.dart';
import '../common/branded_loader.dart';
import '../../domain/feed_dedup.dart';
import '../../domain/streak_provider.dart';
import '../../domain/topic_provider.dart';
import '../../domain/youtube_provider.dart';
import 'shorts_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  /// 하단 탭 셸에서 '피드 탭이 선택됨' 여부. IndexedStack은 비활성 탭을
  /// 그리지 않을 뿐 트리에 남겨 두므로, 이 플래그로 재생 여부를 제어한다.
  final bool active;
  const FeedScreen({super.key, this.active = true});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _refreshing = false;

  /// 피드 화면이 실제로 보이는지(탭 전환·다른 화면에 가려지면 false).
  /// false면 ShortsWidget이 재생을 멈춰 배경 재생음을 막는다.
  bool _screenVisible = true;

  /// 가변 상태(youtubeVideosProvider)에 시드한 토픽 키. 토픽이 바뀌면
  /// 키가 달라져 새 목록으로 다시 시드한다.
  String? _seededKey;

  // ── 무한 스크롤(page token) 상태 (화면 세션 범위) ──
  /// 토픽 → 다음 페이지 토큰 (키 없으면 아직 더 받기 시작 안 함)
  final Map<String, String?> _nextToken = {};

  /// 토픽 → 연속 페이지에 쓸 동일 접미사 (첫 페이지에서 받은 값 재사용)
  final Map<String, String> _suffix = {};

  /// 토큰이 소진된(더 받을 페이지 없는) 토픽
  final Set<String> _exhausted = {};
  bool _loadingMore = false;

  /// 시청한 영상 id (피드 중복 제거용)
  Set<String> _watchedIds = {};

  /// 이번 세션에 학습 활동(스트릭)을 기록했는지
  bool _streakRecorded = false;

  /// 시청 기록에 1회 저장한다. 메모리 집합도 갱신해 다음 페이지에서 제외된다.
  /// 첫 시청 시 '오늘 학습 활동'으로 스트릭도 기록한다(프로필이 아닌 실제 학습 기준).
  void _onWatched(YoutubeVideo v) {
    _watchedIds.add(v.videoId);
    ref.read(youtubeRepositoryProvider).recordWatched(v);
    if (!_streakRecorded) {
      _streakRecorded = true;
      ref.read(streakRepositoryProvider).recordActivity().then((_) {
        if (mounted) ref.invalidate(streakProvider);
      });
    }
  }

  Future<void> _loadWatchedIds() async {
    final ids = await ref.read(youtubeRepositoryProvider).loadWatchedIds();
    if (mounted) _watchedIds = ids;
  }

  /// 이미 본 영상을 제외한다. 모두 본 경우(빈 결과)엔 빈 피드가 되지 않게
  /// 원본을 그대로 보여준다(폴백).
  List<YoutubeVideo> _excludeWatched(List<YoutubeVideo> videos) {
    final filtered =
        videos.where((v) => !_watchedIds.contains(v.videoId)).toList();
    return filtered.isEmpty ? videos : filtered;
  }

  /// 토픽 변경/새로고침 시 무한 스크롤 커서를 초기화한다.
  void _resetPagination() {
    _nextToken.clear();
    _suffix.clear();
    _exhausted.clear();
    _loadingMore = false;
  }

  /// 피드 끝에 가까워지면 토픽별 다음 페이지를 받아 중복 없이 이어붙인다.
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final topics = ref.read(selectedTopicsProvider).toList()..sort();
    final pending = topics.where((t) => !_exhausted.contains(t)).toList();
    if (pending.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final repo = ref.read(youtubeRepositoryProvider);
      var combined = [...ref.read(youtubeVideosProvider)];
      for (final topic in pending) {
        final res = await repo.searchTopicPage(
          topic,
          pageToken: _nextToken[topic],
          suffix: _suffix[topic],
          level: ref.read(selectedLevelProvider),
        );
        _suffix[topic] = res.suffix;
        if (res.nextPageToken == null) {
          _exhausted.add(topic);
        } else {
          _nextToken[topic] = res.nextPageToken;
        }
        combined = dedupeAppend(combined, res.videos, excludedIds: _watchedIds);
      }
      if (!mounted) return;
      ref.read(youtubeVideosProvider.notifier).state = combined;
    } catch (_) {
      // 더 받기 실패는 조용히 무시(기존 피드는 유지). 다음 스크롤에서 재시도.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 현재 토픽으로 새 영상을 강제로 받아와 피드를 갱신한다.
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final topics = ref.read(selectedTopicsProvider).toList()..sort();
    try {
      // 최신 시청 기록을 반영해 이미 본 영상이 다시 뜨지 않게 한다.
      await _loadWatchedIds();
      final fresh = await ref.read(youtubeRepositoryProvider).fetchAndCache(
            topics,
            level: ref.read(selectedLevelProvider),
          );
      if (!mounted) return;
      _resetPagination();
      ref.read(youtubeVideosProvider.notifier).state = _excludeWatched(fresh);
      _currentIndex = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로고침에 실패했어요. 잠시 후 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// 인앱 재생이 불가한 영상을 피드와 캐시에서 제거한다.
  /// 현재 보던 영상이면 그 자리에 다음 영상이 들어와 자동으로 넘어간다.
  void _onUnplayable(String videoId) {
    final list = [...ref.read(youtubeVideosProvider)];
    final idx = list.indexWhere((v) => v.videoId == videoId);
    if (idx == -1) return;
    list.removeAt(idx);
    ref.read(youtubeVideosProvider.notifier).state = list;
    ref.read(youtubeRepositoryProvider).markUnplayable(videoId);
    // 마지막 영상을 지운 경우 현재 인덱스를 끝으로 보정한다.
    if (_currentIndex >= list.length && list.isNotEmpty) {
      _currentIndex = list.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
    if (mounted) {
      _showSkipNotice();
      setState(() {});
    }
  }

  /// 재생 불가 영상을 건너뛸 때 짧게 알린다(연속 스킵 시 쌓이지 않게 교체).
  void _showSkipNotice() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('재생할 수 없는 영상이라 다음으로 넘어갔어요'),
        duration: Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xE61A1A2E),
        margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(selectedTopicsProvider).toList()..sort();
    final key = topics.join('|');
    final videosAsync = ref.watch(youtubeFeedProvider(key));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // 영상이 AppBar 뒤까지 풀화면으로
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('오늘의 학습',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Spacer(),
            if (_refreshing)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: '새로고침',
              ),
          ],
        ),
      ),
      body: videosAsync.when(
        data: (fetchedVideos) {
          // provider를 항상 watch해야 갱신이 리빌드를 트리거한다.
          final stateVideos = ref.watch(youtubeVideosProvider);

          // 토픽 키가 바뀌면(또는 최초) 가변 상태를 새 목록으로 시드한다.
          if (_seededKey != key) {
            _seededKey = key;
            _resetPagination();
            // 시청 기록을 불러온 뒤 이미 본 영상을 제외하고 시드한다.
            _loadWatchedIds().then((_) {
              if (!mounted) return;
              ref.read(youtubeVideosProvider.notifier).state =
                  _excludeWatched(fetchedVideos);
              _currentIndex = 0;
              if (_pageController.hasClients) _pageController.jumpToPage(0);
            });
            return _buildPager(fetchedVideos);
          }

          if (stateVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('재생 가능한 영상이 없습니다.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
            );
          }
          return _buildPager(stateVideos);
        },
        loading: () =>
            const BrandedLoader(label: '학습 쇼츠를 불러오는 중...', onDark: true),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('영상을 불러오지 못했습니다.',
                  style: TextStyle(color: Colors.white70)),
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

  Widget _buildPager(List<YoutubeVideo> list) {
    return VisibilityDetector(
      key: const ValueKey('feed-visibility'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0;
        if (visible != _screenVisible && mounted) {
          setState(() => _screenVisible = visible);
        }
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: list.length,
      onPageChanged: (i) {
        HapticFeedback.selectionClick(); // 스와이프 전환 촉각 피드백
        setState(() => _currentIndex = i);
        // 끝에서 2번째에 도달하면 다음 묶음을 미리 받아온다(무한 스크롤).
        if (i >= list.length - 2) _loadMore();
      },
      itemBuilder: (context, index) {
        final video = list[index];
        return ShortsWidget(
          key: ValueKey(video.videoId),
          video: video,
          isActive: index == _currentIndex,
          // 피드 탭이 선택돼 있고(active) 화면이 가려지지 않았을 때만 재생.
          screenVisible: widget.active && _screenVisible,
          onWatched: () => _onWatched(video),
          onUnplayable: () => _onUnplayable(video.videoId),
          onBookmark: () {
            final updated = video.copyWith(isBookmarked: !video.isBookmarked);
            final newList = [...ref.read(youtubeVideosProvider)];
            final i = newList.indexWhere((v) => v.videoId == video.videoId);
            if (i != -1) newList[i] = updated;
            ref.read(youtubeVideosProvider.notifier).state = newList;
            ref
                .read(youtubeRepositoryProvider)
                .toggleBookmark(video.videoId, updated.isBookmarked);
          },
        );
      },
      ),
    );
  }
}
