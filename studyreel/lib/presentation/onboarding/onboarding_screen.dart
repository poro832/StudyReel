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
              const Text('어떤 걸\n배우고 싶나요?',
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              const Text('3개 이상 선택해 주세요.',
                  style: TextStyle(color: kTextGray)),
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
                        color: isSelected
                            ? kPrimaryColor.withValues(alpha: 0.25)
                            : kCardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : Colors.white24,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(topic,
                          style: TextStyle(
                              color: isSelected ? kPrimaryColor : kTextGray,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Text('${selected.length}개 선택됨',
                  style: const TextStyle(color: kTextGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      notifier.isValid ? () => context.go('/feed') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor:
                        kPrimaryColor.withValues(alpha: 0.3),
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
