import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class BibleMemorizationCompanionApp extends StatelessWidget {
  const BibleMemorizationCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Memorization Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
