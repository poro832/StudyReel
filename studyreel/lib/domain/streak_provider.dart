import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/streak_repository.dart';

final streakRepositoryProvider =
    Provider<StreakRepository>((_) => StreakRepository());

/// 현재 스트릭을 '읽기'만 한다(기록은 학습 활동 시점에 feed가 수행).
/// 프로필 진입만으로 스트릭이 오르던 문제를 바로잡는다.
final streakProvider = FutureProvider<int>((ref) async {
  return ref.read(streakRepositoryProvider).currentStreak();
});
