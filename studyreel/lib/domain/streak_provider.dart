import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/streak_repository.dart';

final streakRepositoryProvider =
    Provider<StreakRepository>((_) => StreakRepository());

/// 프로필 진입 시 오늘 활동을 기록하고 갱신된 스트릭을 반환
final streakProvider = FutureProvider<int>((ref) async {
  return ref.read(streakRepositoryProvider).recordActivity();
});
