import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

const _ytApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const _searchEndpoint = 'https://www.googleapis.com/youtube/v3/search';
const _videosEndpoint = 'https://www.googleapis.com/youtube/v3/videos';

/// 피드에 노출할 최대 영상 길이(초). 쇼츠 형태 유지를 위해 60초 이하만.
const _maxShortsSeconds = 60;

class YoutubeService {
  /// 토픽별 학습 쇼츠 검색 (피드용).
  /// 인앱 임베드 가능 + 60초 이하 영상만 반환한다.
  /// 검색 정렬 기준 후보. 매 fetch마다 무작위로 골라, 같은 토픽이라도
  /// 새로고침할 때 다른 영상이 나오도록 한다.
  static const _orders = ['relevance', 'viewCount', 'date', 'rating'];

  Future<List<YoutubeVideo>> searchShorts(List<String> topics) async {
    final order = _orders[Random().nextInt(_orders.length)];
    final videos = <YoutubeVideo>[];
    for (final topic in topics) {
      final items = await _search(
        query: '$topic 쇼츠',
        maxResults: 15,
        videoDuration: 'short', // 4분 미만 (정밀 길이 필터는 아래에서)
        order: order,
      );
      videos.addAll(_parseItems(items, topic));
    }
    final playable = await _filterPlayableShorts(videos);
    playable.shuffle(); // 토픽이 섞이도록 + 새로고침 때 순서가 달라지도록
    return playable;
  }

  /// 키워드 자유 검색 (탐색 화면용). 탐색은 외부 실행이라 필터 미적용.
  Future<List<YoutubeVideo>> searchByKeyword(String query) async {
    final items = await _search(query: query, maxResults: 15);
    return _parseItems(items, query);
  }

  Future<List<dynamic>> _search({
    required String query,
    required int maxResults,
    String? videoDuration,
    String? order,
  }) async {
    final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      if (videoDuration != null) 'videoDuration': videoDuration,
      if (order != null) 'order': order,
      'maxResults': '$maxResults',
      'relevanceLanguage': 'ko',
      'regionCode': 'KR',
      'key': _ytApiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'YouTube API 오류: ${response.statusCode}\n${response.body}');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['items'] as List;
  }

  /// videos.list(part=status,contentDetails)로 한 번에 검증 (1 unit/회):
  /// - status.embeddable == true (인앱 임베드 가능, Error 152 회피)
  /// - contentDetails.duration <= 60초 (쇼츠 형태 유지)
  /// id는 최대 50개씩 끊어 호출한다.
  Future<List<YoutubeVideo>> _filterPlayableShorts(
      List<YoutubeVideo> videos) async {
    if (videos.isEmpty) return [];

    // 통과한 영상의 id → 길이(초) 매핑
    final passed = <String, int>{};
    for (var i = 0; i < videos.length; i += 50) {
      final chunk = videos.sublist(i, (i + 50).clamp(0, videos.length));
      final ids = chunk.map((v) => v.videoId).join(',');
      final uri = Uri.parse(_videosEndpoint).replace(queryParameters: {
        'part': 'status,contentDetails',
        'id': ids,
        'key': _ytApiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
            'YouTube videos API 오류: ${response.statusCode}\n${response.body}');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      for (final item in body['items'] as List) {
        final embeddable = item['status']?['embeddable'] == true;
        final seconds =
            _parseIsoDuration(item['contentDetails']?['duration'] as String?);
        if (embeddable && seconds > 0 && seconds <= _maxShortsSeconds) {
          passed[item['id'] as String] = seconds;
        }
      }
    }

    return videos
        .where((v) => passed.containsKey(v.videoId))
        .map((v) =>
            v.copyWith(embeddable: true, durationSeconds: passed[v.videoId]))
        .toList();
  }

  /// ISO 8601 기간(PT#H#M#S)을 초로 변환. 파싱 실패 시 0.
  int _parseIsoDuration(String? iso) {
    if (iso == null) return 0;
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (m == null) return 0;
    final h = int.tryParse(m.group(1) ?? '') ?? 0;
    final min = int.tryParse(m.group(2) ?? '') ?? 0;
    final s = int.tryParse(m.group(3) ?? '') ?? 0;
    return h * 3600 + min * 60 + s;
  }

  List<YoutubeVideo> _parseItems(List<dynamic> items, String topic) {
    final videos = <YoutubeVideo>[];
    for (final item in items) {
      final id = item['id']['videoId'] as String?;
      if (id == null) continue;
      final snippet = item['snippet'] as Map<String, dynamic>;
      final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
      final thumbUrl = (thumbnails['high'] ??
          thumbnails['medium'] ??
          thumbnails['default'])['url'] as String;
      videos.add(YoutubeVideo(
        videoId: id,
        title: snippet['title'] as String,
        channelTitle: snippet['channelTitle'] as String,
        topic: topic,
        thumbnailUrl: thumbUrl,
      ));
    }
    return videos;
  }
}
