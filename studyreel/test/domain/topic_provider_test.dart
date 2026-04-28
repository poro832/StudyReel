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
  });
}
