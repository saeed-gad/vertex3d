import 'package:flutter/material.dart';

import 'models.dart';

const kPrimary = Color(0xFF00236F);
const kPrimaryContainer = Color(0xFF1E3A8A);
const kGreen = Color(0xFF006C49);
const kWhatsapp = Color(0xFF25D366);

ColorScheme _light() => const ColorScheme(
      brightness: Brightness.light,
      primary: kPrimary,
      onPrimary: Colors.white,
      primaryContainer: kPrimaryContainer,
      onPrimaryContainer: Color(0xFF90A8FF),
      secondary: kGreen,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF6CF8BB),
      onSecondaryContainer: Color(0xFF00714D),
      tertiary: Color(0xFF3E2400),
      onTertiary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F9FB),
      onSurface: Color(0xFF191C1E),
      onSurfaceVariant: Color(0xFF444651),
      outline: Color(0xFF757682),
      outlineVariant: Color(0xFFC5C5D3),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF3F4F6),
      surfaceContainer: Color(0xFFEDEEF0),
      surfaceContainerHigh: Color(0xFFE7E8EA),
      surfaceContainerHighest: Color(0xFFE1E2E4),
    );

ColorScheme _dark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB6C4FF),
      onPrimary: Color(0xFF00236F),
      primaryContainer: kPrimaryContainer,
      onPrimaryContainer: Color(0xFFDCE1FF),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF002113),
      secondaryContainer: Color(0xFF005236),
      onSecondaryContainer: Color(0xFF6FFBBE),
      tertiary: Color(0xFFFFB95F),
      onTertiary: Color(0xFF2A1700),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF111318),
      onSurface: Color(0xFFE2E2E9),
      onSurfaceVariant: Color(0xFFC5C5D3),
      outline: Color(0xFF8F909C),
      outlineVariant: Color(0xFF444651),
      surfaceContainerLowest: Color(0xFF0C0E13),
      surfaceContainerLow: Color(0xFF1A1B21),
      surfaceContainer: Color(0xFF1E1F25),
      surfaceContainerHigh: Color(0xFF282A2F),
      surfaceContainerHighest: Color(0xFF33353A),
    );

ThemeData buildTheme(bool dark) {
  final cs = dark ? _dark() : _light();
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? kPrimaryContainer : kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: cs.surfaceContainerLowest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerLow,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: dark ? kPrimaryContainer : kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surfaceContainerLowest,
      indicatorColor: cs.primary.withValues(alpha: .12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? kPrimaryContainer : kPrimary,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

class StatusStyle {
  final Color bg, fg;
  const StatusStyle(this.bg, this.fg);
}

StatusStyle statusStyle(DisplayStatus s, bool dark) {
  switch (s) {
    case DisplayStatus.paid:
      return dark
          ? const StatusStyle(Color(0xFF00382A), Color(0xFF6CF8BB))
          : const StatusStyle(Color(0xFF6CF8BB), Color(0xFF00714D));
    case DisplayStatus.pending:
      return dark
          ? const StatusStyle(Color(0xFF4A2E00), Color(0xFFFFB95F))
          : const StatusStyle(Color(0xFFFFDDB8), Color(0xFF653E00));
    case DisplayStatus.overdue:
      return dark
          ? const StatusStyle(Color(0xFF5A0A0A), Color(0xFFFFB4AB))
          : const StatusStyle(Color(0xFFFFDAD6), Color(0xFF93000A));
    case DisplayStatus.draft:
      return dark
          ? const StatusStyle(Color(0xFF33353A), Color(0xFFC5C5D3))
          : const StatusStyle(Color(0xFFE1E2E4), Color(0xFF444651));
  }
}

Color statusAccent(DisplayStatus s) {
  switch (s) {
    case DisplayStatus.paid:
      return const Color(0xFF006C49);
    case DisplayStatus.pending:
      return const Color(0xFFE59A00);
    case DisplayStatus.overdue:
      return const Color(0xFFBA1A1A);
    case DisplayStatus.draft:
      return const Color(0xFF9A9BA8);
  }
}
