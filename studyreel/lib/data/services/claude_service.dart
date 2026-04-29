import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/study_card.dart';

// API 키는 빌드 시 --dart-define=GEMINI_API_KEY=... 로 주입
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

class ClaudeService {
  Future<List<StudyCard>> generateCards(
      List<String> topics, int count) async {
    final topicStr = topics.join(', ');

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''다음 관심사 분야에서 대학생이 2분 안에 읽을 수 있는 학습 카드 $count개를 JSON 배열로 생성하세요.
관심사: $topicStr

각 카드는 다음 형식을 따르세요:
{
  "id": "고유 UUID (8자리 영숫자)",
  "topic": "분야명",
  "title": "개념 제목 (15자 이내)",
  "oneLiner": "한 줄 설명 (30자 이내)",
  "points": ["핵심 포인트 1", "핵심 포인트 2", "핵심 포인트 3"],
  "keywords": ["검색 키워드1", "검색 키워드2"],
  "quiz": {
    "question": "이 개념에 대한 객관식 질문 1개",
    "options": ["선택지A", "선택지B", "선택지C", "선택지D"],
    "answerIndex": 0,
    "hint": "틀렸을 때 보여줄 힌트 1문장"
  }
}

JSON 배열만 반환하세요. 마크다운 코드블록 없이 순수 JSON만.'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API 오류: ${response.statusCode}\n${response.body}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final text =
        (body['candidates'][0]['content']['parts'][0]['text'] as String)
            .trim();

    final cleaned = text
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
        .trim();

    final list = jsonDecode(cleaned) as List;
    return list
        .map((e) => StudyCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
