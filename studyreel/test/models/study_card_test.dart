import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/data/models/study_card.dart';

void main() {
  group('StudyCard', () {
    final sampleJson = {
      'id': 'card-1',
      'topic': '컴퓨터과학',
      'title': '재귀함수',
      'oneLiner': '자기 자신을 호출하는 함수',
      'points': ['Base Case 필요', '스택 사용', '트리 탐색에 활용'],
      'keywords': ['재귀', 'recursion'],
    };

    test('fromJson 파싱 정상', () {
      final card = StudyCard.fromJson(sampleJson);
      expect(card.id, 'card-1');
      expect(card.points.length, 3);
    });

    test('toJson 직렬화 정상', () {
      final card = StudyCard.fromJson(sampleJson);
      expect(card.toJson()['title'], '재귀함수');
    });
  });
}
