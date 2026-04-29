import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/card_repository.dart';
import 'package:studyreel/data/models/study_card.dart';

void main() {
  group('CardRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late CardRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      repo = CardRepository(firestore: fakeFirestore, auth: mockAuth);
    });

    test('saveCards — Firestore에 카드 저장', () async {
      final cards = [
        const StudyCard(
          id: 'c1',
          topic: '수학',
          title: '미적분',
          oneLiner: '변화율',
          points: ['a', 'b', 'c'],
          keywords: ['calculus'],
        ),
      ];
      await repo.saveCards(cards);
      final snap = await fakeFirestore
          .collection('users')
          .doc(mockAuth.currentUser!.uid)
          .collection('cards')
          .get();
      expect(snap.docs.length, 1);
    });

    test('loadCards — 저장된 카드 불러오기', () async {
      final cards = [
        const StudyCard(
          id: 'c2',
          topic: '역사',
          title: '조선시대',
          oneLiner: '500년 왕조',
          points: ['a', 'b', 'c'],
          keywords: ['조선'],
        ),
      ];
      await repo.saveCards(cards);
      final loaded = await repo.loadCards();
      expect(loaded.first.id, 'c2');
    });

    test('toggleBookmark — 북마크 상태 토글', () async {
      final card = const StudyCard(
        id: 'c3',
        topic: '과학',
        title: '양자역학',
        oneLiner: '파동-입자 이중성',
        points: ['a', 'b', 'c'],
        keywords: ['quantum'],
      );
      await repo.saveCards([card]);
      await repo.toggleBookmark('c3', true);
      final loaded = await repo.loadCards();
      expect(loaded.first.isBookmarked, isTrue);
    });
  });
}
