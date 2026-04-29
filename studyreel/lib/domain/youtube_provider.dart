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
