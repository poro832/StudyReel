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

  Future<List<YoutubeVideo>> loadCached() async {
    final snap = await _videosRef.get();
    return snap.docs.map((d) {
      final data = d.data();
      return YoutubeVideo(
        videoId: data['videoId'] as String,
        title: data['title'] as String,
        channelTitle: data['channelTitle'] as String,
        topic: data['topic'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String,
        isBookmarked: data['isBookmarked'] as bool? ?? false,
      );
    }).toList();
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
}
