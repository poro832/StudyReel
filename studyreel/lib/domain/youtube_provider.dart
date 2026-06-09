import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/youtube_video.dart';
import '../data/repositories/youtube_repository.dart';
import 'topic_provider.dart';

final youtubeRepositoryProvider =
    Provider<YoutubeRepository>((_) => YoutubeRepository());

final youtubeVideosProvider = StateProvider<List<YoutubeVideo>>((_) => []);

/// 토픽들을 정렬·조인해 만든 안정적인 문자열 키를 받는다.
/// `List<String>`을 family 키로 쓰면 매 빌드마다 새 List 인스턴스가 만들어져
/// FutureProvider가 무한 재실행되는 문제를 회피하기 위함.
final youtubeFeedProvider =
    FutureProvider.family<List<YoutubeVideo>, String>(
  (ref, topicsKey) async {
    final topics = topicsKey.split('|');
    final repo = ref.read(youtubeRepositoryProvider);
    final cached = await repo.loadCached(topics: topics);
    // 선택한 토픽 전부가 캐시에 있을 때만 캐시 사용. 하나라도 없으면
    // (새 카테고리 선택) 새로 받아온다.
    final covered = cached.map((v) => v.topic).toSet();
    final allCovered = topics.every(covered.contains);
    return (allCovered && cached.isNotEmpty)
        ? cached
        : await repo.fetchAndCache(topics,
            level: ref.read(selectedLevelProvider));
  },
);

/// 탐색 화면 키워드 검색 결과 (빈 쿼리는 빈 목록)
final searchResultsProvider =
    FutureProvider.family<List<YoutubeVideo>, String>(
  (ref, query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return ref.read(youtubeRepositoryProvider).search(q);
  },
);

/// 프로필 화면 — 북마크된 영상 목록
final bookmarkedVideosProvider =
    FutureProvider<List<YoutubeVideo>>((ref) async {
  return ref.read(youtubeRepositoryProvider).loadBookmarked();
});

/// 프로필 화면 — 최근 본 영상 (시청 기록, watchedAt 내림차순)
final watchHistoryProvider =
    FutureProvider<List<YoutubeVideo>>((ref) async {
  return ref.read(youtubeRepositoryProvider).loadWatchHistory();
});
