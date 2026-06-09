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

  group('YoutubeService.isPlayableInApp — 인앱 재생 가능 판정', () {
    test('제약 없는 일반 영상은 재생 가능', () {
      expect(YoutubeService.isPlayableInApp(uploadStatus: 'processed'), isTrue);
      expect(YoutubeService.isPlayableInApp(), isTrue);
    });

    test('연령제한(ytAgeRestricted) 영상은 배제', () {
      expect(YoutubeService.isPlayableInApp(ytRating: 'ytAgeRestricted'),
          isFalse);
    });

    test('한국(KR)이 차단된 영상은 배제', () {
      expect(YoutubeService.isPlayableInApp(regionBlocked: ['KR']), isFalse);
      expect(
          YoutubeService.isPlayableInApp(regionBlocked: ['US']), isTrue);
    });

    test('허용 지역 목록에 KR이 없으면 배제', () {
      expect(YoutubeService.isPlayableInApp(regionAllowed: ['US', 'JP']),
          isFalse);
      expect(YoutubeService.isPlayableInApp(regionAllowed: ['KR', 'US']),
          isTrue);
    });

    test('업로드 상태가 processed가 아니면 배제(rejected/failed 등)', () {
      expect(YoutubeService.isPlayableInApp(uploadStatus: 'rejected'), isFalse);
      expect(YoutubeService.isPlayableInApp(uploadStatus: 'failed'), isFalse);
    });
  });

  group('YoutubeService.qualityScore — 학습 품질 점수', () {
    test('교육 카테고리(27)가 비교육 카테고리보다 높은 점수', () {
      final edu = YoutubeService.qualityScore(
          categoryId: '27', viewCount: 10000, likeCount: 100);
      final other = YoutubeService.qualityScore(
          categoryId: '22', viewCount: 10000, likeCount: 100);
      expect(edu, greaterThan(other));
    });

    test('조회수가 높을수록 점수가 높다', () {
      final high =
          YoutubeService.qualityScore(categoryId: '27', viewCount: 1000000);
      final low =
          YoutubeService.qualityScore(categoryId: '27', viewCount: 1000);
      expect(high, greaterThan(low));
    });

    test('같은 조회수면 좋아요 비율이 높을수록 점수가 높다', () {
      final liked = YoutubeService.qualityScore(
          categoryId: '27', viewCount: 10000, likeCount: 500);
      final fewer = YoutubeService.qualityScore(
          categoryId: '27', viewCount: 10000, likeCount: 10);
      expect(liked, greaterThan(fewer));
    });

    test('값이 없어도(null) 0 이상으로 안전하게 처리', () {
      expect(YoutubeService.qualityScore(), greaterThanOrEqualTo(0));
    });
  });
}
