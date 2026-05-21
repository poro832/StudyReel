import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/youtube_repository.dart';
import 'package:studyreel/data/models/youtube_video.dart';

void main() {
  group('YoutubeRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late YoutubeRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true);
      repo = YoutubeRepository(firestore: firestore, auth: auth);
    });

    const v1 = YoutubeVideo(
      videoId: 'a1',
      title: '미적분 1분 정리',
      channelTitle: '수학채널',
      topic: '수학',
      thumbnailUrl: 'http://x/a1.jpg',
      embeddable: true,
      durationSeconds: 45,
    );
    const v2 = YoutubeVideo(
      videoId: 'b2',
      title: '양자역학 입문',
      channelTitle: '과학채널',
      topic: '과학',
      thumbnailUrl: 'http://x/b2.jpg',
      embeddable: true,
      durationSeconds: 58,
    );

    test('saveAll → loadCached 라운드트립', () async {
      await repo.saveAll([v1, v2]);
      final loaded = await repo.loadCached();
      expect(loaded.map((e) => e.videoId), containsAll(['a1', 'b2']));
    });

    test('loadCached — embeddable=false 영상은 제외', () async {
      const blocked = YoutubeVideo(
        videoId: 'c3',
        title: '임베드 차단 영상',
        channelTitle: '채널',
        topic: '수학',
        thumbnailUrl: 'http://x/c3.jpg',
        embeddable: false,
        durationSeconds: 30,
      );
      await repo.saveAll([v1, blocked]);
      final loaded = await repo.loadCached();
      expect(loaded.map((e) => e.videoId), ['a1']);
    });

    test('loadCached — 60초 초과 영상은 제외 (쇼츠만)', () async {
      const longVideo = YoutubeVideo(
        videoId: 'd4',
        title: '20분 강의',
        channelTitle: '채널',
        topic: '수학',
        thumbnailUrl: 'http://x/d4.jpg',
        embeddable: true,
        durationSeconds: 1200,
      );
      await repo.saveAll([v1, longVideo]);
      final loaded = await repo.loadCached();
      expect(loaded.map((e) => e.videoId), ['a1']);
    });

    test('loadBookmarked — 북마크된 영상만 반환', () async {
      await repo.saveAll([v1, v2]);
      await repo.toggleBookmark('a1', true);
      final marked = await repo.loadBookmarked();
      expect(marked.length, 1);
      expect(marked.first.videoId, 'a1');
      expect(marked.first.isBookmarked, isTrue);
    });

    test('loadBookmarked — 북마크 없으면 빈 목록', () async {
      await repo.saveAll([v1, v2]);
      expect(await repo.loadBookmarked(), isEmpty);
    });
  });
}
