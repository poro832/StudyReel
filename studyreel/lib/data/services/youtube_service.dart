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
  /// 교육용 검색 접미사. "쇼츠"는 예능·바이럴 쇼츠를 끌어와 학습에 부적합한
  /// 영상이 많아지므로, 학습 의도가 담긴 키워드를 쓰고 매 fetch마다 무작위로
  /// 골라 같은 토픽이라도 새로고침 때 다른 영상이 나오도록 한다.
  static const _eduSuffixes = ['강의', '개념 정리', '쉽게 설명', '핵심 요약', '기초'];

  /// 제목에 들어가면 교육용으로 부적합하다고 보는 예능·바이럴 키워드.
  /// 소문자로 비교하므로 영어는 소문자로 적는다(한글은 영향 없음).
  static const _blockedTitleKeywords = [
    '예능', '먹방', '몰카', '직캠', '브이로그', 'vlog', '챌린지', '레전드',
    '꿀잼', '짤', '밈', '개그', '웃긴', '리액션', '커버댄스', '댄스커버',
    '뮤비', 'mv', '뮤직비디오', '게임플레이', 'asmr', 'funny', 'game',
  ];

  /// 배제할 YouTube 영상 카테고리 ID.
  /// 10=음악, 20=게임, 23=코미디, 24=엔터테인먼트.
  static const _blockedCategoryIds = {'10', '20', '23', '24'};

  /// 제목·카테고리 기반 교육 적합성 판정 (순수 함수).
  /// 예능·바이럴·부적합 신호가 있으면 false. 제목 신호가 카테고리보다 우선한다.
  static bool isEducational(String title, {String? categoryId}) {
    final lower = title.toLowerCase();
    for (final kw in _blockedTitleKeywords) {
      if (lower.contains(kw)) return false;
    }
    if (categoryId != null && _blockedCategoryIds.contains(categoryId)) {
      return false;
    }
    return true;
  }

  /// 피드 노출 지역(한국).
  static const _regionCode = 'KR';

  /// 인앱(IFrame) 재생 가능성 판정 (순수 함수).
  /// API가 embeddable=true라 해도 실제로는 막히는 케이스를 메타데이터로 거른다:
  /// - 연령제한(ytAgeRestricted)은 서드파티 플레이어에서 재생 불가
  /// - 한국이 차단(blocked)되거나 허용목록(allowed)에 한국이 없으면 재생 불가
  /// - 업로드 상태가 processed가 아니면(rejected/failed 등) 재생 불가
  static bool isPlayableInApp({
    String? ytRating,
    List<String>? regionBlocked,
    List<String>? regionAllowed,
    String? uploadStatus,
  }) {
    if (ytRating == 'ytAgeRestricted') return false;
    if (regionBlocked != null && regionBlocked.contains(_regionCode)) {
      return false;
    }
    if (regionAllowed != null && !regionAllowed.contains(_regionCode)) {
      return false;
    }
    if (uploadStatus != null && uploadStatus != 'processed') return false;
    return true;
  }

  /// 학습 품질 점수(높을수록 우선). 교육 카테고리 가산점 + 조회수(로그) +
  /// 좋아요/조회수 참여도 비율을 합산한다. 값이 없으면 0으로 안전 처리.
  static int qualityScore({
    String? categoryId,
    int? viewCount,
    int? likeCount,
  }) {
    var score = 0;
    // 교육 성격 카테고리 가산점: 27 교육, 28 과학기술, 26 How-to,
    // 25 뉴스, 22 인물/블로그, 29 비영리(교육 채널 다수).
    const eduBoost = {
      '27': 50,
      '28': 35,
      '26': 30,
      '25': 12,
      '22': 10,
      '29': 10,
    };
    score += eduBoost[categoryId] ?? 0;
    final views = viewCount ?? 0;
    if (views > 0) {
      // log10(views)*10 → 1천:30, 1만:40, 10만:50, 100만:60
      score += (log(views) / ln10 * 10).round();
      if (likeCount != null && likeCount > 0) {
        // 좋아요/조회수 비율(보통 0.01~0.05)에 가산점(상한 50)
        score += (likeCount / views * 1000).round().clamp(0, 50);
      }
    }
    return score;
  }

  /// 토픽별로 묶어 라운드로빈으로 섞는다(품질 순서는 토픽 내에서 유지).
  /// 여러 토픽이 골고루 나오면서도 각 토픽의 상위 품질 영상이 먼저 온다.
  static List<YoutubeVideo> _interleaveByTopic(List<YoutubeVideo> videos) {
    final byTopic = <String, List<YoutubeVideo>>{};
    for (final v in videos) {
      (byTopic[v.topic] ??= []).add(v);
    }
    final queues = byTopic.values.toList();
    final result = <YoutubeVideo>[];
    for (var i = 0; ; i++) {
      var addedAny = false;
      for (final q in queues) {
        if (i < q.length) {
          result.add(q[i]);
          addedAny = true;
        }
      }
      if (!addedAny) break;
    }
    return result;
  }

  Future<List<YoutubeVideo>> searchShorts(List<String> topics,
      {String level = ''}) async {
    final suffix = _eduSuffixes[Random().nextInt(_eduSuffixes.length)];
    final videos = <YoutubeVideo>[];
    for (final topic in topics) {
      final body = await _search(
        query: [topic, if (level.isNotEmpty) level, suffix].join(' '),
        maxResults: 15,
        videoDuration: 'short', // 4분 미만 (정밀 길이 필터는 아래에서)
        // 조회수/최신순은 예능을 상위로 끌어올려 교육 관련성을 떨어뜨림.
        // relevance(기본)로 학습 쿼리와의 관련성을 우선한다.
        order: 'relevance',
      );
      videos.addAll(_parseItems(body['items'] as List, topic));
    }
    // 품질 순(_filterPlayableShorts가 정렬)으로 받아 토픽을 라운드로빈으로 섞는다.
    final playable = await _filterPlayableShorts(videos);
    return _interleaveByTopic(playable);
  }

  /// 무한 스크롤용: 한 토픽의 한 페이지를 받아 필터링한 영상과 다음 페이지
  /// 토큰을 함께 반환한다. [pageToken]이 없으면 1페이지부터 시작한다.
  /// [suffix]를 주면 같은 쿼리로 연속 페이지를 받을 수 있다(없으면 무작위).
  Future<({List<YoutubeVideo> videos, String? nextPageToken, String suffix})>
      searchTopicPage(
    String topic, {
    String? pageToken,
    String? suffix,
    String level = '',
  }) async {
    final s = suffix ?? _eduSuffixes[Random().nextInt(_eduSuffixes.length)];
    final body = await _search(
      query: [topic, if (level.isNotEmpty) level, s].join(' '),
      maxResults: 15,
      videoDuration: 'short',
      order: 'relevance',
      pageToken: pageToken,
    );
    final parsed = _parseItems(body['items'] as List, topic);
    final playable = await _filterPlayableShorts(parsed);
    return (
      videos: playable,
      nextPageToken: body['nextPageToken'] as String?,
      suffix: s,
    );
  }

  /// 키워드 검색 (탐색 화면용). 결과를 탭하면 인앱에서 재생되므로 피드와
  /// 동일하게 임베드 가능·60초·교육 적합·재생 가능 필터를 적용한다.
  Future<List<YoutubeVideo>> searchByKeyword(String query) async {
    final body = await _search(
      query: query,
      maxResults: 15,
      videoDuration: 'short',
      order: 'relevance',
    );
    final parsed = _parseItems(body['items'] as List, query);
    return _filterPlayableShorts(parsed);
  }

  Future<Map<String, dynamic>> _search({
    required String query,
    required int maxResults,
    String? videoDuration,
    String? order,
    String? pageToken,
  }) async {
    final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'videoDuration': ?videoDuration,
      'order': ?order,
      'pageToken': ?pageToken,
      'maxResults': '$maxResults',
      'relevanceLanguage': 'ko',
      'regionCode': 'KR',
      // 부적합·성인성 콘텐츠를 API 단계에서 1차 차단.
      'safeSearch': 'strict',
      'key': _ytApiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'YouTube API 오류: ${response.statusCode}\n${response.body}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// videos.list(part=snippet,status,contentDetails)로 한 번에 검증 (1 unit/회):
  /// - status.embeddable == true (인앱 임베드 가능, Error 152 회피)
  /// - contentDetails.duration <= 60초 (쇼츠 형태 유지)
  /// - snippet.categoryId·title 기반 교육 적합성 (isEducational, 예능 배제)
  /// id는 최대 50개씩 끊어 호출한다.
  Future<List<YoutubeVideo>> _filterPlayableShorts(
      List<YoutubeVideo> videos) async {
    if (videos.isEmpty) return [];

    // 통과한 영상의 id → 길이(초), id → 품질 점수 매핑
    final passed = <String, int>{};
    final scores = <String, int>{};
    for (var i = 0; i < videos.length; i += 50) {
      final chunk = videos.sublist(i, (i + 50).clamp(0, videos.length));
      final ids = chunk.map((v) => v.videoId).join(',');
      final uri = Uri.parse(_videosEndpoint).replace(queryParameters: {
        'part': 'snippet,status,contentDetails,statistics',
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
        final status = item['status'] as Map<String, dynamic>?;
        final content = item['contentDetails'] as Map<String, dynamic>?;
        final embeddable = status?['embeddable'] == true;
        final seconds =
            _parseIsoDuration(content?['duration'] as String?);
        final snippet = item['snippet'] as Map<String, dynamic>?;
        final title = snippet?['title'] as String? ?? '';
        final categoryId = snippet?['categoryId'] as String?;
        final educational = isEducational(title, categoryId: categoryId);
        // 연령제한·지역차단·미처리 영상은 embeddable=true라도 실제 재생이 막힌다.
        final region = content?['regionRestriction'] as Map<String, dynamic>?;
        final playable = isPlayableInApp(
          ytRating: (content?['contentRating']
              as Map<String, dynamic>?)?['ytRating'] as String?,
          regionBlocked: (region?['blocked'] as List?)?.cast<String>(),
          regionAllowed: (region?['allowed'] as List?)?.cast<String>(),
          uploadStatus: status?['uploadStatus'] as String?,
        );
        if (embeddable &&
            educational &&
            playable &&
            seconds > 0 &&
            seconds <= _maxShortsSeconds) {
          final id = item['id'] as String;
          passed[id] = seconds;
          final stats = item['statistics'] as Map<String, dynamic>?;
          scores[id] = qualityScore(
            categoryId: categoryId,
            viewCount: int.tryParse(stats?['viewCount'] as String? ?? ''),
            likeCount: int.tryParse(stats?['likeCount'] as String? ?? ''),
          );
        }
      }
    }

    final result = videos
        .where((v) => passed.containsKey(v.videoId))
        .map((v) =>
            v.copyWith(embeddable: true, durationSeconds: passed[v.videoId]))
        .toList();
    // 품질 점수 내림차순 정렬(높은 학습 품질 우선).
    result.sort(
        (a, b) => (scores[b.videoId] ?? 0).compareTo(scores[a.videoId] ?? 0));
    return result;
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
