import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/study_card.dart';
import '../../domain/card_provider.dart';
import '../../domain/topic_provider.dart';
import 'card_widget.dart';

// 피드 내 북마크 토글 상태 (로컬 반영용)
final _feedCardsProvider =
    StateProvider.family<List<StudyCard>, List<String>>((ref, topics) => []);

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(selectedTopicsProvider).toList();
    final cardsAsync = ref.watch(cardFeedProvider(topics));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  const Text('오늘의 학습',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(width: 20),
                  const Text('탐색',
                      style: TextStyle(fontSize: 16, color: kTextGray)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: kPrimaryColor,
                      child: Text('나',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: cardsAsync.when(
                data: (fetchedCards) {
                  final localCards =
                      ref.watch(_feedCardsProvider(topics));
                  final cards =
                      localCards.isEmpty ? fetchedCards : localCards;

                  if (localCards.isEmpty && fetchedCards.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(_feedCardsProvider(topics).notifier)
                          .state = fetchedCards;
                    });
                  }

                  return PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: cards.length,
                    itemBuilder: (context, index) => CardWidget(
                      card: cards[index],
                      onTap: () =>
                          context.push('/detail/${cards[index].id}'),
                      onBookmark: () {
                        final updated = cards[index]
                            .copyWith(isBookmarked: !cards[index].isBookmarked);
                        final newList = [...cards];
                        newList[index] = updated;
                        ref
                            .read(_feedCardsProvider(topics).notifier)
                            .state = newList;
                        ref
                            .read(cardRepositoryProvider)
                            .toggleBookmark(cards[index].id, updated.isBookmarked);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('카드를 불러오지 못했습니다.',
                          style: TextStyle(color: kTextGray)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(cardFeedProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
