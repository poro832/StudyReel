import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_card.dart';
import '../services/claude_service.dart';

class CardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // 로그인 전에도 동작하도록 익명 UID 폴백
  String get _uid => _auth.currentUser?.uid ?? 'guest';

  CollectionReference<Map<String, dynamic>> get _cardsRef =>
      _firestore.collection('users').doc(_uid).collection('cards');

  Future<void> saveCards(List<StudyCard> cards) async {
    final batch = _firestore.batch();
    for (final card in cards) {
      batch.set(_cardsRef.doc(card.id), card.toJson());
    }
    await batch.commit();
  }

  Future<List<StudyCard>> loadCards() async {
    final snap = await _cardsRef.orderBy(FieldPath.documentId).get();
    return snap.docs.map((d) => StudyCard.fromJson(d.data())).toList();
  }

  Future<void> toggleBookmark(String cardId, bool value) async {
    await _cardsRef.doc(cardId).update({'isBookmarked': value});
  }

  Future<List<StudyCard>> fetchAndSaveCards(List<String> topics) async {
    final cards = await ClaudeService().generateCards(topics, 5);
    await saveCards(cards);
    return cards;
  }
}
