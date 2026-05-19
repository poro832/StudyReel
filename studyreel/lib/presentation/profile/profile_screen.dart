import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../domain/streak_provider.dart';
import '../../domain/youtube_provider.dart';
import '../common/video_list_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final bookmarksAsync = ref.watch(bookmarkedVideosProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('프로필',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _StreakCard(streakAsync: streakAsync),
          const SizedBox(height: 24),
          const Text('저장한 영상',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          bookmarksAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('아직 저장한 영상이 없습니다.',
                        style: TextStyle(color: kTextGray)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final v in videos) ...[
                    VideoListTile(video: v),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('북마크를 불러오지 못했습니다.',
                    style: TextStyle(color: kTextGray)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final AsyncValue<int> streakAsync;
  const _StreakCard({required this.streakAsync});

  @override
  Widget build(BuildContext context) {
    final streak = streakAsync.maybeWhen(
      data: (v) => v,
      orElse: () => 0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, Color(0xFF4A42C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              streakAsync.isLoading
                  ? const Text('불러오는 중...',
                      style: TextStyle(color: Colors.white70, fontSize: 14))
                  : Text('$streak일 연속 학습',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('매일 학습하고 스트릭을 이어가세요',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
