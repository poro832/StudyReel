import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/study_card.dart';

class CardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _cardsRef => _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('cards');

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
    final callable =
        FirebaseFunctions.instance.httpsCallable('generateStudyCards');
    final result = await callable.call({'topics': topics, 'count': 5});
    final raw =
        List<Map<String, dynamic>>.from(result.data['cards'] as List);
    final cards = raw.map(StudyCard.fromJson).toList();
    await saveCards(cards);
    return cards;
  }
}
