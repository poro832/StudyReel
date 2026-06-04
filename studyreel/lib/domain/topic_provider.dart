import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/topic_repository.dart';

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

  /// 저장된 토픽으로 전체를 시드한다(기존 선택을 대체).
  void setAll(Iterable<String> topics) {
    state = {...topics};
  }

  bool get isValid => state.length >= 3;
}

final selectedTopicsProvider =
    NotifierProvider<TopicNotifier, Set<String>>(TopicNotifier.new);

final topicRepositoryProvider =
    Provider<TopicRepository>((_) => TopicRepository());

/// 현재 사용자의 저장된 토픽 (시작 분기·시드용)
final userTopicsProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(topicRepositoryProvider).loadTopics();
});
