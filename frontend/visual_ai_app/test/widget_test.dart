import 'package:flutter_test/flutter_test.dart';
import 'package:visual_ai_app/main.dart';

void main() {
  testWidgets('VisualAIApp displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const VisualAIApp());
    expect(find.text('Visual AI App'), findsOneWidget);
  });
}