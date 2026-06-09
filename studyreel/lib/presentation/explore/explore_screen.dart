import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../domain/youtube_provider.dart';
import '../common/video_list_tile.dart';

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
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text('탐색',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.col.text)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: TextStyle(color: context.col.text),
              decoration: InputDecoration(
                hintText: '학습 주제나 키워드를 검색하세요',
                hintStyle: TextStyle(color: context.col.textGray),
                filled: true,
                fillColor: context.col.surface,
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: kPrimaryColor),
                  onPressed: _submit,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text('관심 있는 주제를 검색해보세요',
                        style: TextStyle(color: context.col.textGray)),
                  )
                : resultsAsync.when(
                    data: (videos) {
                      if (videos.isEmpty) {
                        return Center(
                          child: Text('검색 결과가 없습니다.',
                              style: TextStyle(color: context.col.textGray)),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: videos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            VideoListTile(video: videos[i]),
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
                            Text('검색에 실패했습니다.',
                                style: TextStyle(color: context.col.textGray)),
                            const SizedBox(height: 8),
                            Text(
                              'YouTube API 일일 한도를 초과했을 수 있습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.col.textGray, fontSize: 12),
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
