import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/topic_repository.dart';

const kAvailableTopics = [
  '컴퓨터과학', '수학', '영어', '역사',
  '과학', '경제', '디자인', '심리학',
];

/// 학습 수준. 검색어에 붙여 수준에 맞는 영상을 우선 검색한다.
const kLevels = ['초등', '중등', '고등', '대학'];
const kDefaultLevel = '대학';

/// 현재 선택된 수준. 스플래시에서 저장값으로 시드, 프로필/온보딩에서 변경.
final selectedLevelProvider = StateProvider<String>((_) => kDefaultLevel);

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
