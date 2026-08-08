import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'oklch.dart';

class _PaletteTokens {
  const _PaletteTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accent,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color accent;
}

class AppTheme {
  // Text/icon color placed on top of the accent-filled surfaces (buttons,
  // selected nav indicator). Matches the mockup's literal choice of its
  // light palette's `bg` tone for this role in every theme, including dark
  // — needed because collapsing primary/secondary/tertiary to a single
  // accent (including pure black in dark mode) makes Material's seed-derived
  // `onPrimary` unreliable for contrast.
  static final _onAccent = oklchToColor(0.98, 0.01, 90);

  static final _light = _PaletteTokens(
    bg: oklchToColor(0.98, 0.01, 90),
    surface: oklchToColor(0.99, 0.005, 90),
    surfaceAlt: oklchToColor(0.93, 0.015, 260),
    textPrimary: oklchToColor(0.22, 0.02, 260),
    textSecondary: oklchToColor(0.55, 0.03, 260),
    border: oklchToColor(0.85, 0.015, 260),
    accent: const Color(0xFF4B0000),
  );

  static final _sepia = _PaletteTokens(
    bg: oklchToColor(0.93, 0.025, 75),
    surface: oklchToColor(0.95, 0.02, 75),
    surfaceAlt: oklchToColor(0.88, 0.03, 70),
    textPrimary: oklchToColor(0.28, 0.03, 50),
    textSecondary: oklchToColor(0.48, 0.035, 55),
    border: oklchToColor(0.8, 0.03, 65),
    accent: const Color(0xFF4B0000),
  );

  static final _dark = _PaletteTokens(
    bg: oklchToColor(0.2, 0.01, 260),
    surface: oklchToColor(0.27, 0.012, 260),
    surfaceAlt: oklchToColor(0.33, 0.015, 260),
    textPrimary: oklchToColor(0.92, 0.01, 90),
    textSecondary: oklchToColor(0.65, 0.015, 260),
    border: oklchToColor(0.4, 0.015, 260),
    accent: const Color(0xFF000000),
  );

  static ThemeData light() => _build(_light, Brightness.light);

  static ThemeData sepia() => _build(_sepia, Brightness.light);

  static ThemeData dark() => _build(_dark, Brightness.dark);

  static ThemeData _build(_PaletteTokens t, Brightness brightness) {
    // Tint used for low-alpha selection backgrounds (nav indicator, selected
    // chip). Normally the accent itself, but dark mode's accent is pure
    // black on a near-black surface — blending black-on-black at low alpha
    // is invisible, so tint toward the light on-accent color instead.
    final selectionTint = brightness == Brightness.dark ? _onAccent : t.accent;

    final scheme = ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: brightness,
      primary: t.accent,
      onPrimary: _onAccent,
      secondary: t.accent,
      onSecondary: _onAccent,
      tertiary: t.accent,
      onTertiary: _onAccent,
      surface: t.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          height: 1.45,
          color: t.textPrimary,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          height: 1.45,
          color: t.textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: t.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: t.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        indicatorColor: selectionTint.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: t.textPrimary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceAlt,
        selectedColor: selectionTint.withValues(alpha: 0.12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
