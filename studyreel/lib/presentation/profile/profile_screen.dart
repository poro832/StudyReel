import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/auth_provider.dart';
import '../../domain/streak_provider.dart';
import '../../domain/theme_provider.dart';
import '../../domain/topic_provider.dart';
import '../../domain/youtube_provider.dart';
import '../common/video_list_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// 수준을 바꾸고 새 영상을 받아 피드를 갱신한다.
  Future<void> _changeLevel(
      WidgetRef ref, BuildContext context, String level) async {
    if (level == ref.read(selectedLevelProvider)) return;
    ref.read(selectedLevelProvider.notifier).state = level;
    await ref.read(topicRepositoryProvider).saveLevel(level);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text('$level 수준으로 새 영상을 받는 중...'),
      duration: const Duration(seconds: 2),
    ));
    try {
      final topics = ref.read(selectedTopicsProvider).toList()..sort();
      final fresh = await ref
          .read(youtubeRepositoryProvider)
          .fetchAndCache(topics, level: level);
      ref.read(youtubeVideosProvider.notifier).state = fresh;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('영상을 받지 못했어요. 피드에서 새로고침해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final bookmarksAsync = ref.watch(bookmarkedVideosProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text('프로필',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.col.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _AccountCard(
            name: user?.displayName,
            email: user?.email,
            photoUrl: user?.photoURL,
            onSignOut: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 16),
          _StreakCard(streakAsync: streakAsync),
          const SizedBox(height: 16),
          _TopicEditTile(onTap: () => context.push('/topics')),
          const SizedBox(height: 12),
          _ThemeToggleTile(
            isDark: ref.watch(isDarkProvider),
            onChanged: (v) {
              ref.read(isDarkProvider.notifier).state = v;
              ref.read(topicRepositoryProvider).saveThemeDark(v);
            },
          ),
          const SizedBox(height: 12),
          _LevelTile(
            level: ref.watch(selectedLevelProvider),
            onPick: (l) => _changeLevel(ref, context, l),
          ),
          const SizedBox(height: 24),
          Text('저장한 영상',
              style: TextStyle(
                  color: context.col.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          bookmarksAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('아직 저장한 영상이 없습니다.',
                        style: TextStyle(color: context.col.textGray)),
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
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('북마크를 불러오지 못했습니다.',
                    style: TextStyle(color: context.col.textGray)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('최근 본 영상',
              style: TextStyle(
                  color: context.col.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          historyAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('아직 본 영상이 없습니다.',
                        style: TextStyle(color: context.col.textGray)),
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
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('시청 기록을 불러오지 못했습니다.',
                    style: TextStyle(color: context.col.textGray)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String level;
  final ValueChanged<String> onPick;
  const _LevelTile({required this.level, required this.onPick});

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('학습 수준 선택',
                  style: TextStyle(
                      color: context.col.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            for (final l in kLevels)
              ListTile(
                title: Text(l, style: TextStyle(color: context.col.text)),
                trailing: l == level
                    ? const Icon(Icons.check, color: kPrimaryColor)
                    : null,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onPick(l);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.col.border),
          boxShadow: context.col.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: kPrimaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text('학습 수준',
                  style: TextStyle(
                      color: context.col.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Text(level,
                style: const TextStyle(
                    color: kPrimaryColor, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: context.col.textGray),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ThemeToggleTile({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.col.border),
        boxShadow: context.col.cardShadow,
      ),
      child: Row(
        children: [
          Icon(isDark ? Icons.dark_mode : Icons.light_mode,
              color: kPrimaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(isDark ? '다크 모드' : '라이트 모드',
                style: TextStyle(
                    color: context.col.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Switch(
            value: isDark,
            activeColor: kPrimaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TopicEditTile extends StatelessWidget {
  final VoidCallback onTap;
  const _TopicEditTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.col.border),
          boxShadow: context.col.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, color: kPrimaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text('관심 토픽 변경',
                  style: TextStyle(
                      color: context.col.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right, color: context.col.textGray),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String? name;
  final String? email;
  final String? photoUrl;
  final Future<void> Function() onSignOut;

  const _AccountCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.col.border),
        boxShadow: context.col.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kPrimaryColor,
            foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : 'StudyReel 사용자',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.col.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email?.isNotEmpty == true ? email! : 'Google 계정 로그인',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.col.textGray, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            color: context.col.textGray,
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
          colors: [kPrimaryColor, Color(0xFF1B64DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.col.cardShadow,
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
