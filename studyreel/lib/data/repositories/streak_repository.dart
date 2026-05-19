import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 연속 학습일(스트릭)을 Firestore에 기록/조회한다.
/// 문서 경로: users/{uid}/meta/streak
class StreakRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DateTime Function() _now;

  StreakRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DateTime Function()? now,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _now = now ?? DateTime.now;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  DocumentReference<Map<String, dynamic>> get _streakRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('meta')
      .doc('streak');

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 오늘 활동을 기록하고 갱신된 스트릭 값을 반환한다.
  /// - 첫 방문: 1
  /// - 같은 날 재방문: 변동 없음
  /// - 어제 이어서: +1
  /// - 하루 이상 비었으면: 1로 리셋
  Future<int> recordActivity() async {
    final today = _now();
    final todayKey = _dateKey(today);
    final yesterdayKey =
        _dateKey(today.subtract(const Duration(days: 1)));

    final snap = await _streakRef.get();
    int streak;
    if (!snap.exists) {
      streak = 1;
    } else {
      final data = snap.data()!;
      final lastDate = data['lastActiveDate'] as String?;
      final current = data['currentStreak'] as int? ?? 0;
      if (lastDate == todayKey) {
        return current;
      } else if (lastDate == yesterdayKey) {
        streak = current + 1;
      } else {
        streak = 1;
      }
    }
    await _streakRef.set({
      'currentStreak': streak,
      'lastActiveDate': todayKey,
    });
    return streak;
  }

  Future<int> currentStreak() async {
    final snap = await _streakRef.get();
    if (!snap.exists) return 0;
    return snap.data()!['currentStreak'] as int? ?? 0;
  }
}
