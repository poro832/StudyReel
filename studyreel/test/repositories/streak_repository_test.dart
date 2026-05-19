import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/streak_repository.dart';

void main() {
  group('StreakRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late DateTime fakeNow;

    StreakRepository build() => StreakRepository(
          firestore: firestore,
          auth: auth,
          now: () => fakeNow,
        );

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true);
      fakeNow = DateTime(2026, 4, 29);
    });

    test('첫 방문 → 스트릭 1', () async {
      final repo = build();
      expect(await repo.recordActivity(), 1);
    });

    test('같은 날 재방문 → 변동 없음', () async {
      final repo = build();
      await repo.recordActivity();
      expect(await repo.recordActivity(), 1);
    });

    test('연속 다음 날 방문 → +1', () async {
      final repo = build();
      await repo.recordActivity(); // 4/29 → 1
      fakeNow = DateTime(2026, 4, 30);
      expect(await repo.recordActivity(), 2);
    });

    test('하루 이상 비면 → 1로 리셋', () async {
      final repo = build();
      await repo.recordActivity(); // 4/29 → 1
      fakeNow = DateTime(2026, 4, 30);
      await repo.recordActivity(); // → 2
      fakeNow = DateTime(2026, 5, 3); // 3일 공백
      expect(await repo.recordActivity(), 1);
    });

    test('currentStreak — 기록 전 0, 기록 후 반영', () async {
      final repo = build();
      expect(await repo.currentStreak(), 0);
      await repo.recordActivity();
      expect(await repo.currentStreak(), 1);
    });
  });
}
