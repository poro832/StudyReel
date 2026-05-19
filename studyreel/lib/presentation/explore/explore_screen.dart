import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/youtube_launcher.dart';
import '../../data/models/youtube_video.dart';
import '../../domain/youtube_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('탐색',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '학습 주제나 키워드를 검색하세요',
                hintStyle: const TextStyle(color: kTextGray),
                filled: true,
                fillColor: kCardColor,
                prefixIcon: const Icon(Icons.search, color: kTextGray),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: kPrimaryColor),
                  onPressed: _submit,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Text('관심 있는 주제를 검색해보세요',
                        style: TextStyle(color: kTextGray)),
                  )
                : resultsAsync.when(
                    data: (videos) {
                      if (videos.isEmpty) {
                        return const Center(
                          child: Text('검색 결과가 없습니다.',
                              style: TextStyle(color: kTextGray)),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: videos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _ResultTile(video: videos[i]),
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('검색에 실패했습니다.',
                                style: TextStyle(color: kTextGray)),
                            const SizedBox(height: 8),
                            const Text(
                              'YouTube API 일일 한도를 초과했을 수 있습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: kTextGray, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(
                                  searchResultsProvider(_query)),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final YoutubeVideo video;
  const _ResultTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchYoutube(video.videoId),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  video.thumbnailUrl,
                  width: 140,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 140,
                    height: 90,
                    color: kBgColor,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: kTextGray, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
