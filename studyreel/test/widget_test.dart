import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:studyreel/data/repositories/auth_repository.dart';
import 'package:studyreel/domain/auth_provider.dart';
import 'package:studyreel/main.dart';

void main() {
  testWidgets('앱 초기 실행 — 미로그인 시 로그인 화면 표시', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              auth: MockFirebaseAuth(),
              googleSignIn: MockGoogleSignIn(),
            ),
          ),
        ],
        child: const StudyReelApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Google로 계속하기'), findsOneWidget);
  });
}
