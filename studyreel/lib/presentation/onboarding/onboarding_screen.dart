import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/topic_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTopicsProvider);
    final notifier = ref.read(selectedTopicsProvider.notifier);
    final level = ref.watch(selectedLevelProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text('StudyReel',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor)),
              const SizedBox(height: 32),
              Text('어떤 걸\n배우고 싶나요?',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: context.col.text)),
              const SizedBox(height: 12),
              Text('3개 이상 선택해 주세요.',
                  style: TextStyle(color: context.col.textGray)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kAvailableTopics.map((topic) {
                  final isSelected = selected.contains(topic);
                  return GestureDetector(
                    onTap: () => notifier.toggle(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : context.col.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : context.col.border,
                          width: 1,
                        ),
                        boxShadow: isSelected ? null : context.col.cardShadow,
                      ),
                      child: Text(topic,
                          style: TextStyle(
                              color: isSelected ? Colors.white : context.col.text,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('학습 수준',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.col.text)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: kLevels.map((l) {
                  final on = level == l;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(selectedLevelProvider.notifier).state = l,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? kPrimaryColor : context.col.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: on ? kPrimaryColor : context.col.border),
                        boxShadow: on ? null : context.col.cardShadow,
                      ),
                      child: Text(l,
                          style: TextStyle(
                              color: on ? Colors.white : context.col.text,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Text('${selected.length}개 선택됨',
                  style: TextStyle(color: context.col.textGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: notifier.isValid
                      ? () async {
                          final repo = ref.read(topicRepositoryProvider);
                          await repo.saveTopics(selected.toList());
                          await repo.saveLevel(level);
                          if (context.mounted) context.go('/home');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: context.col.border,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('시작하기 →',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
