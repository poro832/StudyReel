import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/theme_provider.dart';
import '../../domain/topic_provider.dart';
import '../common/branded_loader.dart';

/// 로그인 후 진입점. 저장된 관심 토픽을 불러와 분기한다.
/// - 토픽 있음 → 시드 후 피드로 (온보딩 건너뜀)
/// - 토픽 없음(첫 로그인) → 온보딩으로
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(topicRepositoryProvider);
    List<String> topics;
    try {
      // 저장된 테마 설정을 먼저 반영(없으면 기본 다크 유지).
      final dark = await repo.loadThemeDark();
      if (dark != null && mounted) {
        ref.read(isDarkProvider.notifier).state = dark;
      }
      // 저장된 학습 수준 반영(없으면 기본값 유지).
      final level = await repo.loadLevel();
      if (level != null && mounted) {
        ref.read(selectedLevelProvider.notifier).state = level;
      }
      // 분류 개편으로 사라진 옛 토픽(유령)을 걸러낸다. 일부만 유효하면 정리된
      // 목록을 1회 다시 저장해 Firestore도 정합 상태로 맞춘다.
      final saved = await repo.loadTopics();
      topics = sanitizeTopics(saved);
      if (topics.isNotEmpty && topics.length != saved.length) {
        await repo.saveTopics(topics);
      }
    } catch (_) {
      topics = const [];
    }
    if (!mounted) return;
    ref.read(selectedTopicsProvider.notifier).setAll(topics);
    context.go(topics.isEmpty ? '/onboarding' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BrandedLoader(),
    );
  }
}
