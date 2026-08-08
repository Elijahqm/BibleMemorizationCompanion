import 'package:bible_memorization_companion_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpTheme(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(theme: theme, home: const Scaffold(body: Text('theme'))),
    );
  }

  testWidgets('AppTheme.light builds without error', (tester) async {
    await pumpTheme(tester, AppTheme.light());
    expect(find.text('theme'), findsOneWidget);
  });

  testWidgets('AppTheme.sepia builds without error', (tester) async {
    await pumpTheme(tester, AppTheme.sepia());
    expect(find.text('theme'), findsOneWidget);
  });

  testWidgets('AppTheme.dark builds without error', (tester) async {
    await pumpTheme(tester, AppTheme.dark());
    expect(find.text('theme'), findsOneWidget);
  });

  test('accent color resolves to the correct token per theme', () {
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF4B0000));
    expect(AppTheme.sepia().colorScheme.primary, const Color(0xFF4B0000));
    expect(AppTheme.dark().colorScheme.primary, const Color(0xFF000000));
  });
}
