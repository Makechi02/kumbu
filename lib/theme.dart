import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cool off-white and white cards with a deep green accent.
/// Change [accent] and [accentSoft] to restyle the whole app.
class AppColors {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
  });

  final Color paper;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;

  /// A pale tint of the accent, for icon circles, highlights and the nav indicator.
  final Color accentSoft;
  final Color accentInk;

  static const light = AppColors(
    paper: Color(0xFFF5F6F3),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF17201B),
    muted: Color(0xFF66716B),
    line: Color(0xFFE1E6E0),
    accent: Color(0xFF2F6F55),
    accentSoft: Color(0xFFDCEBE3),
    accentInk: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    paper: Color(0xFF0F1412),
    surface: Color(0xFF171E1B),
    ink: Color(0xFFE6ECE8),
    muted: Color(0xFF8A958F),
    line: Color(0xFF263029),
    accent: Color(0xFF6CC4A1),
    accentSoft: Color(0xFF1F3A30),
    accentInk: Color(0xFF07251A),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// The writing surface: Lora, generous leading.
TextStyle entryTextStyle(BuildContext context) {
  return GoogleFonts.lora(
    fontSize: 18,
    height: 1.75,
    color: AppColors.of(context).ink,
  );
}

/// Lora, for headings.
TextStyle serif(
    BuildContext context,
    double size, {
      FontWeight weight = FontWeight.w600,
    }) {
  return GoogleFonts.lora(
    fontSize: size,
    fontWeight: weight,
    color: AppColors.of(context).ink,
  );
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.accentInk,
      secondary: c.accent,
      onSecondary: c.accentInk,
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.accent,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.muted,
      outlineVariant: c.line,
    ),
    textTheme: GoogleFonts.karlaTextTheme(base.textTheme)
        .apply(bodyColor: c.ink, displayColor: c.ink),
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accentSoft,
      elevation: 0,
      height: 68,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: GoogleFonts.karla(color: c.paper, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent),
  );
}