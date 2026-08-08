import 'package:bible_memorization_companion_mobile/core/errors/app_error.dart';
import 'package:bible_memorization_companion_mobile/core/l10n/app_locale.dart';
import 'package:bible_memorization_companion_mobile/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations', () {
    Future<AppLocalizations> load(String code) =>
        AppLocalizations.delegate.load(Locale(code));

    test('exposes only the supported es/en locales', () {
      expect(
        AppLocale.supportedLocales,
        [const Locale('en'), const Locale('es')],
      );
    });

    test('resolves the Spanish translations', () async {
      final es = await load('es');
      expect(es.navStudies, 'Estudios');
      expect(es.navLibrary, 'Biblioteca');
      expect(es.navStore, 'Tienda');
      expect(es.navProgress, 'Progreso');
      expect(es.navSettings, 'Ajustes');
    });

    test('renders a localized message for every error kind', () async {
      final en = await load('en');
      final es = await load('es');

      for (final l10n in [en, es]) {
        for (final kind in AppErrorKind.values) {
          expect(
            localizedAppError(l10n, AppError(kind)).trim(),
            isNotEmpty,
            reason:
                '$kind should map to a non-empty message in ${l10n.localeName}',
          );
        }
        expect(localizedAppError(l10n, StateError('boom')).trim(), isNotEmpty);
      }
    });

    test('parameterized messages interpolate placeholders', () async {
      final es = await load('es');
      expect(es.versesCount(1), '1 versículo');
      expect(es.versesCount(9), '9 versículos');
      expect(es.chaptersCount(1), '1 capítulo');
      expect(es.timeMinutesAgo(1), 'hace 1 minuto');
    });
  });

  group('device locale behavior', () {
    testWidgets('uses Spanish components when the device locale is es', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) => Column(
              children: [
                Text(context.l10n.navStudies),
                Text(context.l10n.navLibrary),
                Text(context.l10n.navStore),
                Text(context.l10n.navProgress),
                Text(context.l10n.navSettings),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estudios'), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Progreso'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
    });

    testWidgets('falls back to English for an unsupported device locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('pt', 'BR'),
          home: Builder(
            builder: (context) => Text(context.l10n.navStudies),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Studies'), findsOneWidget);
    });
  });
}