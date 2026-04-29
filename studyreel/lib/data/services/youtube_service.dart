import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

const _ytApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const _searchEndpoint = 'https://www.googleapis.com/youtube/v3/search';

class YoutubeService {
  Future<List<YoutubeVideo>> searchShorts(List<String> topics) async {
    final videos = <YoutubeVideo>[];

    for (final topic in topics) {
      final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
        'part': 'snippet',
        'q': '$topic 학습 쇼츠',
        'type': 'video',
        'videoDuration': 'short',
        'maxResults': '3',
        'relevanceLanguage': 'ko',
        'regionCode': 'KR',
        'key': _ytApiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('YouTube API 오류: ${response.statusCode}\n${response.body}');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final items = body['items'] as List;

      for (final item in items) {
        final id = item['id']['videoId'] as String?;
        if (id == null) continue;
        final snippet = item['snippet'] as Map<String, dynamic>;
        final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
        final thumbUrl = (thumbnails['high'] ?? thumbnails['medium'] ??
                thumbnails['default'])['url'] as String;
        videos.add(YoutubeVideo(
          videoId: id,
          title: snippet['title'] as String,
          channelTitle: snippet['channelTitle'] as String,
          topic: topic,
          thumbnailUrl: thumbUrl,
        ));
      }
    }

    return videos;
  }
}
