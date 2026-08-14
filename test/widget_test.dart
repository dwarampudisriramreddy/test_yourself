// Basic smoke test for the AI Quiz app.

import 'package:flutter_test/flutter_test.dart';

import 'package:testai/main.dart';

void main() {
  testWidgets('App renders the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TestAiApp());
    await tester.pumpAndSettle();

    expect(find.text('AI Quiz'), findsOneWidget);
    expect(find.text('Enter a topic'), findsOneWidget);
    expect(find.text('GENERATE QUIZ'), findsOneWidget);
  });
}
