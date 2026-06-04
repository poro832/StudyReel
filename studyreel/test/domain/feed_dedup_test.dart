import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/data/models/youtube_video.dart';
import 'package:studyreel/domain/feed_dedup.dart';

YoutubeVideo _v(String id) => YoutubeVideo(
      videoId: id,
      title: 't$id',
      channelTitle: 'c',
      topic: '수학',
      thumbnailUrl: 'http://x/$id.jpg',
    );

void main() {
  group('dedupeAppend', () {
    test('기존에 없는 영상만 뒤에 이어붙인다', () {
      final existing = [_v('a'), _v('b')];
      final incoming = [_v('b'), _v('c'), _v('d')];
      final result = dedupeAppend(existing, incoming);
      expect(result.map((e) => e.videoId), ['a', 'b', 'c', 'd']);
    });

    test('incoming 내부 중복도 제거한다', () {
      final result = dedupeAppend([], [_v('c'), _v('c'), _v('d')]);
      expect(result.map((e) => e.videoId), ['c', 'd']);
    });

    test('excludedIds(시청한 영상)는 제외한다', () {
      final result = dedupeAppend(
        [_v('a')],
        [_v('b'), _v('c')],
        excludedIds: {'b'},
      );
      expect(result.map((e) => e.videoId), ['a', 'c']);
    });

    test('기존 리스트는 그대로 보존하고 새 리스트를 반환한다', () {
      final existing = [_v('a')];
      final result = dedupeAppend(existing, [_v('b')]);
      expect(existing.map((e) => e.videoId), ['a']); // 원본 불변
      expect(result.map((e) => e.videoId), ['a', 'b']);
    });
  });
}
