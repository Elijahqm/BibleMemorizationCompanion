import 'package:flutter/material.dart';

import 'core/l10n/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class BibleMemorizationCompanionApp extends StatelessWidget {
  const BibleMemorizationCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      home: const AppShell(),
    );
  }
}
