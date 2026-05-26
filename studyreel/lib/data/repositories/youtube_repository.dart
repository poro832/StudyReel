import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

class YoutubeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final YoutubeService _service;

  YoutubeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    YoutubeService? service,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _service = service ?? YoutubeService();

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  CollectionReference<Map<String, dynamic>> get _videosRef =>
      _firestore.collection('users').doc(_uid).collection('youtube_videos');

  /// 캐시된 영상을 읽는다. [topics]가 주어지면 해당 토픽의 영상만 반환한다
  /// (새 카테고리를 고르면 캐시에 없어 재조회가 유도됨). 북마크 조회처럼
  /// 토픽 무관하게 전부 필요할 때는 [topics]를 생략한다.
  Future<List<YoutubeVideo>> loadCached({List<String>? topics}) async {
    final snap = await _videosRef.get();
    return snap.docs
        .map((d) {
          final data = d.data();
          return YoutubeVideo(
            videoId: data['videoId'] as String,
            title: data['title'] as String,
            channelTitle: data['channelTitle'] as String,
            topic: data['topic'] as String,
            thumbnailUrl: data['thumbnailUrl'] as String,
            isBookmarked: data['isBookmarked'] as bool? ?? false,
            embeddable: data['embeddable'] as bool? ?? false,
            durationSeconds: data['durationSeconds'] as int? ?? 0,
          );
        })
        // 임베드 가능 + 60초 이하 쇼츠만 노출. 해당 필드 없는 구버전 캐시는
        // 자동 제외되어 fetchAndCache로 재조회를 유도한다.
        .where((v) =>
            v.embeddable &&
            v.durationSeconds > 0 &&
            v.durationSeconds <= 60 &&
            (topics == null || topics.contains(v.topic)))
        .toList();
  }

  Future<void> saveAll(List<YoutubeVideo> videos) async {
    final batch = _firestore.batch();
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
      });
    }
    await batch.commit();
  }

  Future<void> toggleBookmark(String videoId, bool value) async {
    await _videosRef.doc(videoId).update({'isBookmarked': value});
  }

  Future<List<YoutubeVideo>> fetchAndCache(List<String> topics) async {
    final videos = await _service.searchShorts(topics);
    if (videos.isNotEmpty) await saveAll(videos);
    return videos;
  }

  /// 키워드 검색은 캐싱하지 않고 매번 새로 조회 (임의 쿼리로 Firestore 오염 방지)
  Future<List<YoutubeVideo>> search(String query) =>
      _service.searchByKeyword(query);

  /// 북마크된 영상만 반환 (프로필 화면용)
  Future<List<YoutubeVideo>> loadBookmarked() async {
    final all = await loadCached();
    return all.where((v) => v.isBookmarked).toList();
  }
}
