import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/data/services/youtube_service.dart';

void main() {
  group('YoutubeService.isEducational — 콘텐츠 큐레이션 판정', () {
    test('일반 학습 제목은 통과', () {
      expect(YoutubeService.isEducational('미적분 핵심 개념 1분 정리'), isTrue);
      expect(YoutubeService.isEducational('양자역학 쉽게 설명'), isTrue);
    });

    test('예능·바이럴 키워드가 제목에 있으면 배제', () {
      expect(YoutubeService.isEducational('수학쌤 먹방 레전드'), isFalse);
      expect(YoutubeService.isEducational('아이돌 직캠 모음'), isFalse);
      expect(YoutubeService.isEducational('현실웃긴 챌린지 ㅋㅋ'), isFalse);
      expect(YoutubeService.isEducational('일상 브이로그 vlog'), isFalse);
    });

    test('영어 예능 키워드도 대소문자 무관하게 배제', () {
      expect(YoutubeService.isEducational('NewJeans MV official'), isFalse);
      expect(YoutubeService.isEducational('Funny Game Highlight'), isFalse);
    });

    test('예능 카테고리(24)·음악(10)·게임(20)·코미디(23)는 배제', () {
      expect(
          YoutubeService.isEducational('제목은 평범', categoryId: '24'), isFalse);
      expect(
          YoutubeService.isEducational('제목은 평범', categoryId: '10'), isFalse);
      expect(
          YoutubeService.isEducational('제목은 평범', categoryId: '20'), isFalse);
      expect(
          YoutubeService.isEducational('제목은 평범', categoryId: '23'), isFalse);
    });

    test('교육(27)·과학기술(28)·How-to(26) 카테고리는 통과', () {
      expect(
          YoutubeService.isEducational('알고리즘 강의', categoryId: '27'), isTrue);
      expect(
          YoutubeService.isEducational('반도체 원리', categoryId: '28'), isTrue);
      expect(
          YoutubeService.isEducational('엑셀 사용법', categoryId: '26'), isTrue);
    });

    test('교육 카테고리라도 제목에 예능 키워드면 배제 (제목 우선)', () {
      expect(YoutubeService.isEducational('먹방 하면서 공부', categoryId: '27'),
          isFalse);
    });
  });
}
