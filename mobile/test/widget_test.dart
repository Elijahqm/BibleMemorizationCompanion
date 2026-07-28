import 'package:flutter_test/flutter_test.dart';

import 'package:bible_memorization_companion_mobile/app.dart';

void main() {
  testWidgets('app shell renders primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BibleMemorizationCompanionApp());

    expect(find.text('My Studies'), findsOneWidget);
    expect(find.text('Library'), findsAtLeastNWidgets(1));
    expect(find.text('Progress'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });
}
