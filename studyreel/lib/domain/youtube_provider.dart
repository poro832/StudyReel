import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/youtube_video.dart';
import '../data/repositories/youtube_repository.dart';

final youtubeRepositoryProvider =
    Provider<YoutubeRepository>((_) => YoutubeRepository());

final youtubeVideosProvider = StateProvider<List<YoutubeVideo>>((_) => []);

final youtubeFeedProvider =
    FutureProvider.family<List<YoutubeVideo>, List<String>>(
  (ref, topics) async {
    final repo = ref.read(youtubeRepositoryProvider);
    final cached = await repo.loadCached();
    final videos =
        cached.isNotEmpty ? cached : await repo.fetchAndCache(topics);
    ref.read(youtubeVideosProvider.notifier).state = videos;
    return videos;
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
