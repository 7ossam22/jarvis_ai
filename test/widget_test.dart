import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/main.dart';

void main() {
  testWidgets('Jarvis app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JarvisApp());
    expect(find.text('J.A.R.V.I.S'), findsWidgets);
  });
}
