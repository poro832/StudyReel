import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/study_card.dart';

class CardWidget extends StatelessWidget {
  final StudyCard card;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const CardWidget({
    super.key,
    required this.card,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(card.topic,
                    style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 20),
              Text(card.title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(card.oneLiner,
                  style: const TextStyle(color: kTextGray, fontSize: 14)),
              const Divider(color: Colors.white12, height: 40),
              ...card.points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✦ ',
                            style: TextStyle(
                                color: kPrimaryColor, fontSize: 12)),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  color: Color(0xFFD8D8E8),
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              Row(
                children: [
                  GestureDetector(
                    onTap: onBookmark,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: card.isBookmarked
                            ? kPrimaryColor.withValues(alpha: 0.2)
                            : kCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: card.isBookmarked
                              ? kPrimaryColor
                              : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        card.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color:
                            card.isBookmarked ? kPrimaryColor : kTextGray,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: kRedAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kRedAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Center(
                        child: Text('▶  관련 유튜브 쇼츠 보기',
                            style: TextStyle(
                                color: Color(0xFFFF8080),
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
