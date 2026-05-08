// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:smilecheck/main.dart';
import 'package:smilecheck/services/ai_service.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Create a dummy AiService for testing
    final aiService = AiService();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(aiService: aiService));

    // Verify the app is running without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
