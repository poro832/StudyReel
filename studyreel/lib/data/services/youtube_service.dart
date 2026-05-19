import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

const _ytApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const _searchEndpoint = 'https://www.googleapis.com/youtube/v3/search';

class YoutubeService {
  /// 토픽별 학습 쇼츠 검색 (피드용)
  Future<List<YoutubeVideo>> searchShorts(List<String> topics) async {
    final videos = <YoutubeVideo>[];
    for (final topic in topics) {
      final items = await _search(
        query: '$topic 학습 쇼츠',
        maxResults: 3,
        videoDuration: 'short',
      );
      videos.addAll(_parseItems(items, topic));
    }
    return videos;
  }

  /// 키워드 자유 검색 (탐색 화면용)
  Future<List<YoutubeVideo>> searchByKeyword(String query) async {
    final items = await _search(query: query, maxResults: 15);
    return _parseItems(items, query);
  }

  Future<List<dynamic>> _search({
    required String query,
    required int maxResults,
    String? videoDuration,
  }) async {
    final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      if (videoDuration != null) 'videoDuration': videoDuration,
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
