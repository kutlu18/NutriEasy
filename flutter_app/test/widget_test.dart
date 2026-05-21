import 'package:flutter_test/flutter_test.dart';

import 'package:nutri_easy_flutter/app/nutri_easy_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NutriEasy app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const NutriEasyApp(bootstrapOnStart: false));

    expect(find.text('NutriEasy'), findsOneWidget);
  });
}
