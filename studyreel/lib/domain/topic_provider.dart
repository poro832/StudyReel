import 'package:flutter_riverpod/flutter_riverpod.dart';

const kAvailableTopics = [
  '컴퓨터과학', '수학', '영어', '역사',
  '과학', '경제', '디자인', '심리학',
];

class TopicNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String topic) {
    if (state.contains(topic)) {
      state = {...state}..remove(topic);
    } else {
      state = {...state, topic};
    }
  }

  bool get isValid => state.length >= 3;
}

final selectedTopicsProvider =
    NotifierProvider<TopicNotifier, Set<String>>(TopicNotifier.new);
