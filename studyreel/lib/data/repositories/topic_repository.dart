import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 사용자가 고른 관심 토픽을 계정별로 영속화한다.
/// `users/{uid}` 문서의 `topics` 배열에 저장한다.
class TopicRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TopicRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// 선택한 토픽을 저장한다(기존 목록 교체).
  Future<void> saveTopics(List<String> topics) async {
    await _userDoc.set({'topics': topics}, SetOptions(merge: true));
  }

  /// 저장된 토픽을 불러온다. 없으면 빈 목록.
  Future<List<String>> loadTopics() async {
    final snap = await _userDoc.get();
    final raw = snap.data()?['topics'] as List?;
    return raw?.cast<String>() ?? const [];
  }

  /// 테마 설정(다크 여부)을 저장한다.
  Future<void> saveThemeDark(bool dark) async {
    await _userDoc.set({'themeDark': dark}, SetOptions(merge: true));
  }

  /// 저장된 테마 설정을 불러온다. 없으면 null(기본 다크 사용).
  Future<bool?> loadThemeDark() async {
    final snap = await _userDoc.get();
    return snap.data()?['themeDark'] as bool?;
  }
}
