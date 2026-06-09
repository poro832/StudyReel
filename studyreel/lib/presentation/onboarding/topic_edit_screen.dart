import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/topic_provider.dart';
import '../../domain/youtube_provider.dart';

/// 프로필에서 진입하는 관심 토픽 변경 화면.
/// 현재 토픽을 로컬 초안으로 편집하고, 저장 시에만 영속화·피드 반영한다.
class TopicEditScreen extends ConsumerStatefulWidget {
  const TopicEditScreen({super.key});

  @override
  ConsumerState<TopicEditScreen> createState() => _TopicEditScreenState();
}

class _TopicEditScreenState extends ConsumerState<TopicEditScreen> {
  late Set<String> _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = {...ref.read(selectedTopicsProvider)};
  }

  bool get _isValid => _draft.length >= 3;

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    final topics = _draft.toList();
    try {
      await ref.read(topicRepositoryProvider).saveTopics(topics);
      ref.read(selectedTopicsProvider.notifier).setAll(topics);
      // 토픽이 바뀌었으니 피드를 새 토픽으로 다시 받도록 무효화한다.
      ref.invalidate(youtubeFeedProvider);
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('토픽 저장에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text('관심 토픽 변경',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: context.col.text)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('관심 있는 분야를\n3개 이상 골라주세요.',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: context.col.text)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kAvailableTopics.map((topic) {
                  final isSelected = _draft.contains(topic);
                  return GestureDetector(
                    onTap: () => setState(() {
                      isSelected ? _draft.remove(topic) : _draft.add(topic);
                    }),
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
              const Spacer(),
              Text('${_draft.length}개 선택됨',
                  style: TextStyle(color: context.col.textGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isValid && !_saving ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: context.col.border,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_saving ? '저장 중...' : '저장',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
