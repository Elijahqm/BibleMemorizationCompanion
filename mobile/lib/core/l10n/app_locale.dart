import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Single source of truth for the app's locale configuration.
///
/// `supportedLocales` and `localizationsDelegates` come from the generated
/// [AppLocalizations] class so `MaterialApp`, the widget tests and any future
/// manual locale override all agree on the same set.
class AppLocale {
  const AppLocale._();

  /// Locale used when the device language is not among [supportedLocales].
  static const Locale fallback = Locale('en');

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      AppLocalizations.localizationsDelegates;
}

/// Convenience accessor so widgets can write `context.l10n.*` instead of
/// `AppLocalizations.of(context).*`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
