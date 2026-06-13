import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyreel/domain/topic_provider.dart';

void main() {
  group('TopicNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('초기 상태: 선택된 토픽 없음', () {
      final topics = container.read(selectedTopicsProvider);
      expect(topics, isEmpty);
    });

    test('토픽 토글: 추가', () {
      container.read(selectedTopicsProvider.notifier).toggle('컴퓨터과학');
      expect(container.read(selectedTopicsProvider), contains('컴퓨터과학'));
    });

    test('토픽 토글: 이미 있으면 제거', () {
      final notifier = container.read(selectedTopicsProvider.notifier);
      notifier.toggle('컴퓨터과학');
      notifier.toggle('컴퓨터과학');
      expect(container.read(selectedTopicsProvider), isEmpty);
    });

    test('isValid: 3개 이상 선택 시 true', () {
      final notifier = container.read(selectedTopicsProvider.notifier);
      notifier.toggle('A');
      notifier.toggle('B');
      notifier.toggle('C');
      expect(container.read(selectedTopicsProvider.notifier).isValid, isTrue);
    });

    test('setAll: 저장된 토픽으로 전체 시드(기존 선택 대체)', () {
      final notifier = container.read(selectedTopicsProvider.notifier);
      notifier.toggle('수학');
      notifier.setAll(['컴퓨터과학', '영어', '과학']);
      expect(container.read(selectedTopicsProvider),
          {'컴퓨터과학', '영어', '과학'});
    });
  });

  group('sanitizeTopics — 분류 개편 유령 토픽 제거', () {
    test('현재 분류에 없는 옛 토픽은 제거, 유효한 것만 순서대로 유지', () {
      // 컴퓨터과학·수학(옛 선택 토픽, 현재는 헤더/삭제) 제거 / 역사·알고리즘 유지
      expect(sanitizeTopics(['컴퓨터과학', '역사', '수학', '알고리즘']),
          ['역사', '알고리즘']);
    });

    test('모두 유효하면 그대로', () {
      expect(sanitizeTopics(['알고리즘', '미적분']), ['알고리즘', '미적분']);
    });

    test('모두 옛 분류면 빈 목록(→ 온보딩 재진입 유도)', () {
      expect(sanitizeTopics(['컴퓨터과학', '영어', '과학']), isEmpty);
    });
  });
}
