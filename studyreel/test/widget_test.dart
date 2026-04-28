import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/main.dart';

void main() {
  testWidgets('앱 초기 실행 — 온보딩 화면 표시', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StudyReelApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('어떤 걸\n배우고 싶나요?'), findsOneWidget);
  });
}
