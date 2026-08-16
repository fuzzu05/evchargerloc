import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartEVApp());
    expect(find.byType(SmartEVApp), findsOneWidget);
  });
}
