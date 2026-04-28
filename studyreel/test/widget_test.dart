import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/main.dart';

void main() {
  testWidgets('앱 초기 실행 — 온보딩 화면 표시', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StudyReelApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('온보딩 화면 (Task 3에서 구현)'), findsOneWidget);
  });
}
