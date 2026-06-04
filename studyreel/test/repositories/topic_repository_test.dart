import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/topic_repository.dart';

void main() {
  group('TopicRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late TopicRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true);
      repo = TopicRepository(firestore: firestore, auth: auth);
    });

    test('저장 전에는 빈 목록', () async {
      expect(await repo.loadTopics(), isEmpty);
    });

    test('saveTopics → loadTopics 라운드트립', () async {
      await repo.saveTopics(['컴퓨터과학', '수학', '영어']);
      expect(await repo.loadTopics(), ['컴퓨터과학', '수학', '영어']);
    });

    test('saveTopics — 다시 저장하면 새 목록으로 교체', () async {
      await repo.saveTopics(['수학', '영어', '과학']);
      await repo.saveTopics(['역사', '경제', '디자인']);
      expect(await repo.loadTopics(), ['역사', '경제', '디자인']);
    });
  });
}
