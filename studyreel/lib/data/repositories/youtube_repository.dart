import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

class YoutubeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final YoutubeService _service;

  /// 캐시 신선도(cachedAt) 계산용 시계. 테스트에서 주입해 결정적으로 검증한다.
  final DateTime Function() _now;

  YoutubeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    YoutubeService? service,
    DateTime Function()? now,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _service = service ?? YoutubeService(),
        _now = now ?? DateTime.now;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  CollectionReference<Map<String, dynamic>> get _videosRef =>
      _firestore.collection('users').doc(_uid).collection('youtube_videos');

  CollectionReference<Map<String, dynamic>> get _watchHistoryRef =>
      _firestore.collection('users').doc(_uid).collection('watch_history');

  /// 캐시된 영상을 읽는다. [topics]가 주어지면 해당 토픽의 영상만 반환한다
  /// (새 카테고리를 고르면 캐시에 없어 재조회가 유도됨). 북마크 조회처럼
  /// 토픽 무관하게 전부 필요할 때는 [topics]를 생략한다.
  /// [maxAge]를 주면 그보다 오래된(또는 cachedAt이 없는 구버전) 캐시는 만료로
  /// 보고 제외해, 재방문 사용자에게도 신선한 영상이 재조회되도록 한다.
  Future<List<YoutubeVideo>> loadCached(
      {List<String>? topics, Duration? maxAge}) async {
    final snap = await _videosRef.get();
    final nowMs = _now().millisecondsSinceEpoch;
    final out = <YoutubeVideo>[];
    for (final d in snap.docs) {
      final data = d.data();
      // TTL: cachedAt이 없거나(구버전 캐시) maxAge를 초과하면 만료로 제외 →
      // youtubeFeedProvider가 fetchAndCache로 신선한 영상을 받아온다.
      if (maxAge != null) {
        final cachedAt = data['cachedAt'] as int?;
        if (cachedAt == null || nowMs - cachedAt > maxAge.inMilliseconds) {
          continue;
        }
      }
      final v = YoutubeVideo(
        videoId: data['videoId'] as String,
        title: data['title'] as String,
        channelTitle: data['channelTitle'] as String,
        topic: data['topic'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String,
        isBookmarked: data['isBookmarked'] as bool? ?? false,
        embeddable: data['embeddable'] as bool? ?? false,
        durationSeconds: data['durationSeconds'] as int? ?? 0,
      );
      // 임베드 가능 + 60초 이하 쇼츠만 노출. 해당 필드 없는 구버전 캐시는
      // 자동 제외되어 fetchAndCache로 재조회를 유도한다.
      if (v.embeddable &&
          v.durationSeconds > 0 &&
          v.durationSeconds <= 60 &&
          (topics == null || topics.contains(v.topic))) {
        out.add(v);
      }
    }
    return out;
  }

  Future<void> saveAll(List<YoutubeVideo> videos) async {
    final batch = _firestore.batch();
    final cachedAt = _now().millisecondsSinceEpoch;
    for (final v in videos) {
      batch.set(_videosRef.doc(v.videoId), {
        'videoId': v.videoId,
        'title': v.title,
        'channelTitle': v.channelTitle,
        'topic': v.topic,
        'thumbnailUrl': v.thumbnailUrl,
        'isBookmarked': v.isBookmarked,
        'embeddable': v.embeddable,
        'durationSeconds': v.durationSeconds,
        'cachedAt': cachedAt,
      });
    }
    await batch.commit();
  }

  Future<void> toggleBookmark(String videoId, bool value) async {
    await _videosRef.doc(videoId).update({'isBookmarked': value});
  }

  /// 인앱 재생이 실패한 영상을 캐시에서 제거해 다음부터 피드에 안 뜨게 한다.
  /// 단, 사용자가 북마크한 영상은 보존한다(의도적으로 저장한 것).
  Future<void> markUnplayable(String videoId) async {
    final doc = _videosRef.doc(videoId);
    final snap = await doc.get();
    if (snap.data()?['isBookmarked'] == true) return;
    await doc.delete();
  }

  /// 새 영상을 받아 캐시를 갱신한다. 해당 토픽의 기존 영상 중 북마크되지
  /// 않은 것은 삭제해, 오래된·부적합 영상이 다음 로드에 계속 섞이지 않게 한다.
  /// (북마크된 영상은 보존하고, 새 영상이 기존 북마크와 같으면 상태 유지)
  Future<List<YoutubeVideo>> fetchAndCache(List<String> topics,
      {String level = ''}) async {
    final videos = await _service.searchShorts(topics, level: level);
    if (videos.isEmpty) return videos;

    final snap = await _videosRef.get();
    final bookmarkedIds = <String>{};
    final batch = _firestore.batch();
    final cachedAt = _now().millisecondsSinceEpoch;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isBookmarked'] == true) bookmarkedIds.add(doc.id);
      final topic = data['topic'] as String?;
      if (topic != null &&
          topics.contains(topic) &&
          data['isBookmarked'] != true) {
        batch.delete(doc.reference);
      }
    }
    for (final v in videos) {
      batch.set(_videosRef.doc(v.videoId), {
        'videoId': v.videoId,
        'title': v.title,
        'channelTitle': v.channelTitle,
        'topic': v.topic,
        'thumbnailUrl': v.thumbnailUrl,
        'isBookmarked': bookmarkedIds.contains(v.videoId),
        'embeddable': v.embeddable,
        'durationSeconds': v.durationSeconds,
        'cachedAt': cachedAt,
      });
    }
    await batch.commit();
    return videos;
  }

  /// 영상이 실제 재생된 시점에 시청 기록으로 저장한다.
  /// 재시청하면 watchedAt이 갱신돼 "최근 본 영상" 정렬에서 앞으로 온다.
  Future<void> recordWatched(YoutubeVideo v, {DateTime? at}) async {
    await _watchHistoryRef.doc(v.videoId).set({
      'videoId': v.videoId,
      'title': v.title,
      'channelTitle': v.channelTitle,
      'topic': v.topic,
      'thumbnailUrl': v.thumbnailUrl,
      'watchedAt': (at ?? DateTime.now()).millisecondsSinceEpoch,
    });
  }

  /// 최근 본 영상을 watchedAt 내림차순으로 반환 (프로필 표시용).
  Future<List<YoutubeVideo>> loadWatchHistory({int limit = 30}) async {
    final snap = await _watchHistoryRef
        .orderBy('watchedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return YoutubeVideo(
        videoId: data['videoId'] as String,
        title: data['title'] as String,
        channelTitle: data['channelTitle'] as String,
        topic: data['topic'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String,
      );
    }).toList();
  }

  /// 시청한 영상 id 집합 (피드 중복 제거용).
  Future<Set<String>> loadWatchedIds() async {
    final snap = await _watchHistoryRef.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// 무한 스크롤용: 한 토픽의 다음 페이지를 받아온다(서비스 위임).
  Future<({List<YoutubeVideo> videos, String? nextPageToken, String suffix})>
      searchTopicPage(String topic,
              {String? pageToken, String? suffix, String level = ''}) =>
          _service.searchTopicPage(topic,
              pageToken: pageToken, suffix: suffix, level: level);

  /// 키워드 검색은 캐싱하지 않고 매번 새로 조회 (임의 쿼리로 Firestore 오염 방지)
  Future<List<YoutubeVideo>> search(String query) =>
      _service.searchByKeyword(query);

  /// 북마크된 영상만 반환 (프로필 화면용)
  Future<List<YoutubeVideo>> loadBookmarked() async {
    final all = await loadCached();
    return all.where((v) => v.isBookmarked).toList();
  }
}
