import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/topic_repository.dart';

/// 학습 카테고리 → 세부 토픽. 세부 토픽 문자열이 곧 YouTube 검색어가 되므로
/// (`[토픽, 수준, 접미사].join(' ')`), 구체적일수록 교육 콘텐츠 매칭이 정확해져
/// 예능 혼입이 줄어든다. 키(이모지 포함)는 표시용 헤더, 값만 선택 대상이다.
const kTopicGroups = <String, List<String>>{
  '💻 컴퓨터·IT': ['알고리즘', '자료구조', '웹개발', '인공지능', '데이터베이스', '네트워크'],
  '🔢 수학': ['미적분', '선형대수', '확률·통계', '기하'],
  '🔬 과학': ['물리', '화학', '생명과학', '천문·우주'],
  '🗣️ 어학': ['영어회화', '영문법', '토익·토플'],
  '📚 인문·사회': ['역사', '철학', '심리학', '경제'],
  '🎨 예술·디자인': ['디자인', '음악이론', '영화'],
};

/// 전체 세부 토픽(평면) — 검증·시드용.
final List<String> kAvailableTopics =
    kTopicGroups.values.expand((e) => e).toList(growable: false);

/// 저장된 토픽 중 현재 분류(kAvailableTopics)에 존재하는 것만 남긴다(순수 함수).
/// 분류 개편으로 사라진 옛 토픽(예: '컴퓨터과학', '수학')은 칩이 없어 UI로 해제할 수
/// 없으므로, 로드 경계에서 걸러 피드·선택 화면에 '유령 토픽'이 남지 않게 한다.
List<String> sanitizeTopics(Iterable<String> topics) =>
    topics.where(kAvailableTopics.contains).toList();

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
