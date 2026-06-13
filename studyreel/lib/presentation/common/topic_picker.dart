import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../domain/topic_provider.dart';

/// 카테고리 헤더 + 세부 토픽 칩(그룹형) 선택 위젯.
/// 온보딩과 토픽 편집 화면에서 공유한다(DRY). 선택 모델은 평면 `Set<String>`.
class TopicPicker extends StatelessWidget {
  final Set<String> selected;
  final void Function(String topic) onToggle;

  const TopicPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final groups = kTopicGroups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 10),
            child: Text(
              groups[i].key,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.col.textGray,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final t in groups[i].value) _chip(context, t)],
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String topic) {
    final isSelected = selected.contains(topic);
    return Semantics(
      button: true,
      selected: isSelected,
      label: topic,
      child: GestureDetector(
        onTap: () => onToggle(topic),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : context.col.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? kPrimaryColor : context.col.border,
              width: 1,
            ),
            boxShadow: isSelected ? null : context.col.cardShadow,
          ),
          child: Text(
            topic,
            style: TextStyle(
              color: isSelected ? Colors.white : context.col.text,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
