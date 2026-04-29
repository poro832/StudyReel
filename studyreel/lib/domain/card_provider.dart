import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/card_repository.dart';
import '../data/models/study_card.dart';

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(),
);

// 마지막으로 로드된 카드 목록 전역 캐시 (상세 화면에서 접근)
final cachedCardsProvider = StateProvider<List<StudyCard>>((_) => []);

final cardFeedProvider = FutureProvider.family<List<StudyCard>, List<String>>(
  (ref, topics) async {
    final repo = ref.read(cardRepositoryProvider);
    final cached = await repo.loadCards();
    final cards =
        cached.isNotEmpty ? cached : await repo.fetchAndSaveCards(topics);
    ref.read(cachedCardsProvider.notifier).state = cards;
    return cards;
  },
);
