import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:studyreel/data/models/youtube_video.dart';
import 'package:studyreel/data/repositories/auth_repository.dart';
import 'package:studyreel/data/repositories/topic_repository.dart';
import 'package:studyreel/data/repositories/youtube_repository.dart';
import 'package:studyreel/data/services/youtube_service.dart';
import 'package:studyreel/domain/auth_provider.dart';
import 'package:studyreel/domain/topic_provider.dart';
import 'package:studyreel/domain/youtube_provider.dart';
import 'package:studyreel/main.dart';

/// 풀-플로우(E2E) 통합 테스트: 실제 앱 위젯 트리 + go_router 라우팅 +
/// 여러 화면 전환 + Firestore 영속을 헤드리스로 검증한다.
/// (네트워크/WebView는 가짜 서비스로 대체해 흐름에 집중)

/// 네트워크 대신 빈 결과를 주는 서비스 — 피드가 WebView 없이 빈 상태로
/// 안정적으로 렌더되게 해 라우팅·화면 전환 흐름에 집중한다.
class _EmptyYoutubeService extends YoutubeService {
  @override
  Future<List<YoutubeVideo>> searchShorts(List<String> topics,
          {String level = ''}) async =>
      const [];
}

/// pumpAndSettle은 로딩 애니메이션 때문에 멈추지 않으므로, 고정 간격으로
/// 여러 번 펌프해 비동기(스플래시 부트스트랩·Firestore·피드 future)를 진행시킨다.
Future<void> _advance(WidgetTester tester, {int times = 14}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('E2E — 로그인 사용자: 온보딩에서 토픽 선택 → 홈 피드 진입',
      (WidgetTester tester) async {
    // 온보딩 세로 레이아웃이 잘리지 않도록 폰 크기 뷰포트로 고정.
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(auth: auth, googleSignIn: MockGoogleSignIn()),
          ),
          topicRepositoryProvider.overrideWithValue(
            TopicRepository(firestore: firestore, auth: auth),
          ),
          youtubeRepositoryProvider.overrideWithValue(
            YoutubeRepository(
              firestore: firestore,
              auth: auth,
              service: _EmptyYoutubeService(),
            ),
          ),
        ],
        child: const StudyReelApp(),
      ),
    );

    // 스플래시 부트스트랩(토픽 없음) → 온보딩으로 라우팅
    await _advance(tester);
    expect(find.text('어떤 걸\n배우고 싶나요?'), findsOneWidget);

    // 관심 토픽 3개 선택
    await tester.tap(find.text('컴퓨터과학'));
    await tester.tap(find.text('수학'));
    await tester.tap(find.text('영어'));
    await tester.pump();
    expect(find.text('3개 선택됨'), findsOneWidget);

    // 시작하기 → 토픽 저장 후 홈으로
    await tester.tap(find.text('시작하기 →'));
    await _advance(tester);

    // 홈 셸 도달: 피드 앱바 + 하단 내비게이션
    expect(find.text('오늘의 학습'), findsOneWidget);
    expect(find.text('프로필'), findsWidgets);

    // 저장한 토픽이 실제로 영속화됐는지 확인(통합 관점)
    final saved =
        await TopicRepository(firestore: firestore, auth: auth).loadTopics();
    expect(saved, containsAll(['컴퓨터과학', '수학', '영어']));
  });
}
