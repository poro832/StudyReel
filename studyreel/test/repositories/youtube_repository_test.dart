import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/youtube_repository.dart';
import 'package:studyreel/data/models/youtube_video.dart';
import 'package:studyreel/data/services/youtube_service.dart';

/// fetchAndCache 검증용 — 네트워크 대신 고정 결과를 반환하는 가짜 서비스.
class _FakeYoutubeService extends YoutubeService {
  _FakeYoutubeService(this._result);
  final List<YoutubeVideo> _result;
  @override
  Future<List<YoutubeVideo>> searchShorts(List<String> topics,
          {String level = ''}) async =>
      _result;
}

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

    test('loadCached(topics) — 선택한 토픽의 영상만 반환', () async {
      await repo.saveAll([v1, v2]); // v1=수학, v2=과학
      final math = await repo.loadCached(topics: ['수학']);
      expect(math.map((e) => e.videoId), ['a1']);
    });

    test('fetchAndCache — 같은 토픽 비-북마크 영상은 교체, 북마크는 보존', () async {
      const oldMath = YoutubeVideo(
        videoId: 'old1',
        title: '옛 예능 영상',
        channelTitle: '채널',
        topic: '수학',
        thumbnailUrl: 'http://x/old1.jpg',
        embeddable: true,
        durationSeconds: 40,
      );
      const kept = YoutubeVideo(
        videoId: 'keep1',
        title: '북마크한 영상',
        channelTitle: '채널',
        topic: '수학',
        thumbnailUrl: 'http://x/keep1.jpg',
        embeddable: true,
        durationSeconds: 50,
        isBookmarked: true,
      );
      await repo.saveAll([oldMath, kept]);

      const fresh = YoutubeVideo(
        videoId: 'new1',
        title: '신규 강의',
        channelTitle: '채널',
        topic: '수학',
        thumbnailUrl: 'http://x/new1.jpg',
        embeddable: true,
        durationSeconds: 30,
      );
      final fetchRepo = YoutubeRepository(
        firestore: firestore,
        auth: auth,
        service: _FakeYoutubeService([fresh]),
      );
      await fetchRepo.fetchAndCache(['수학']);

      final loaded = await repo.loadCached(topics: ['수학']);
      final ids = loaded.map((e) => e.videoId).toSet();
      expect(ids, containsAll(['new1', 'keep1'])); // 신규 + 북마크 보존
      expect(ids.contains('old1'), isFalse); // 옛 비북마크 영상 제거
      expect(
        loaded.firstWhere((v) => v.videoId == 'keep1').isBookmarked,
        isTrue,
      );
    });

    test('loadCached(maxAge) — TTL 이내 캐시는 반환', () async {
      final base = DateTime(2026, 6, 10, 12);
      final freshRepo = YoutubeRepository(
        firestore: firestore,
        auth: auth,
        now: () => base,
      );
      await freshRepo.saveAll([v1]); // cachedAt = base
      // 2일 뒤 로드, TTL 3일 → 신선
      final readRepo = YoutubeRepository(
        firestore: firestore,
        auth: auth,
        now: () => base.add(const Duration(days: 2)),
      );
      final loaded =
          await readRepo.loadCached(maxAge: const Duration(days: 3));
      expect(loaded.map((e) => e.videoId), ['a1']);
    });

    test('loadCached(maxAge) — TTL 초과 캐시는 만료로 제외', () async {
      final base = DateTime(2026, 6, 10, 12);
      final freshRepo =
          YoutubeRepository(firestore: firestore, auth: auth, now: () => base);
      await freshRepo.saveAll([v1]); // cachedAt = base
      // 4일 뒤 로드, TTL 3일 → 만료
      final readRepo = YoutubeRepository(
        firestore: firestore,
        auth: auth,
        now: () => base.add(const Duration(days: 4)),
      );
      final loaded =
          await readRepo.loadCached(maxAge: const Duration(days: 3));
      expect(loaded, isEmpty);
    });

    test('loadCached(maxAge 생략) — TTL 미적용 시 오래돼도 반환', () async {
      final base = DateTime(2026, 1, 1);
      final freshRepo =
          YoutubeRepository(firestore: firestore, auth: auth, now: () => base);
      await freshRepo.saveAll([v1]);
      // maxAge 없이 로드 → 나이 무관 반환(loadBookmarked 등 기존 동작 보존)
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

    test('markUnplayable — 재생 불가 영상은 캐시에서 제거', () async {
      await repo.saveAll([v1, v2]);
      await repo.markUnplayable('a1');
      final loaded = await repo.loadCached();
      expect(loaded.map((e) => e.videoId), ['b2']);
    });

    test('markUnplayable — 북마크된 영상은 보존', () async {
      await repo.saveAll([v1, v2]);
      await repo.toggleBookmark('a1', true);
      await repo.markUnplayable('a1');
      final loaded = await repo.loadCached();
      expect(loaded.map((e) => e.videoId), containsAll(['a1', 'b2']));
    });

    test('recordWatched → loadWatchedIds 에 포함', () async {
      await repo.recordWatched(v1);
      final ids = await repo.loadWatchedIds();
      expect(ids, contains('a1'));
    });

    test('loadWatchHistory — 최근 본 순(watchedAt desc)으로 반환', () async {
      await repo.recordWatched(v1, at: DateTime(2026, 6, 1));
      await repo.recordWatched(v2, at: DateTime(2026, 6, 3));
      final history = await repo.loadWatchHistory();
      expect(history.map((e) => e.videoId), ['b2', 'a1']); // 최신 먼저
    });

    test('recordWatched — 재시청 시 watchedAt 갱신(맨 앞으로)', () async {
      await repo.recordWatched(v1, at: DateTime(2026, 6, 1));
      await repo.recordWatched(v2, at: DateTime(2026, 6, 2));
      await repo.recordWatched(v1, at: DateTime(2026, 6, 5)); // a1 재시청
      final history = await repo.loadWatchHistory();
      expect(history.map((e) => e.videoId), ['a1', 'b2']);
    });

    test('loadWatchHistory — limit 적용', () async {
      await repo.recordWatched(v1, at: DateTime(2026, 6, 1));
      await repo.recordWatched(v2, at: DateTime(2026, 6, 2));
      final history = await repo.loadWatchHistory(limit: 1);
      expect(history.length, 1);
      expect(history.first.videoId, 'b2');
    });
  });
}
