import 'package:material_ui/material_ui.dart';

/// Font dibundel di `assets/fonts/` (lihat pubspec.yaml), tidak memakai google_fonts.
///
/// Pembagian (docs/DESIGN_SYSTEM.md):
/// * Fredoka: logo dan judul bernuansa brand (display, title).
/// * Plus Jakarta Sans: semua teks UI lain (heading tempat, body, label, caption).
/// * JetBrains Mono: jam, durasi, nomor kereta.
abstract final class AppFonts {
  static const brand = 'Fredoka';
  static const ui = 'PlusJakartaSans';
  static const mono = 'JetBrainsMono';
}

abstract final class AppTypography {
  static TextStyle _style(
    String family,
    double size,
    double lineHeight,
    FontWeight weight, {
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  /// display = headlineMedium, title = titleLarge, heading = titleMedium,
  /// body = bodyLarge, label = labelLarge, caption = bodySmall.
  static TextTheme textTheme(TextTheme base, Color ink) => base
      .copyWith(
        headlineMedium: _style(AppFonts.brand, 32, 38, FontWeight.w700,
            letterSpacing: -0.32),
        titleLarge: _style(AppFonts.brand, 22, 28, FontWeight.w600),
        titleMedium: _style(AppFonts.ui, 17, 24, FontWeight.w700),
        bodyLarge: _style(AppFonts.ui, 15, 22, FontWeight.w400),
        bodyMedium: _style(AppFonts.ui, 15, 22, FontWeight.w400),
        labelLarge: _style(AppFonts.ui, 13, 18, FontWeight.w600),
        bodySmall: _style(AppFonts.ui, 12, 16, FontWeight.w500),
      )
      .apply(bodyColor: ink, displayColor: ink);

  static TextStyle time({Color? color}) =>
      _style(AppFonts.mono, 20, 24, FontWeight.w600).copyWith(color: color);

  static TextStyle timeSm({Color? color}) =>
      _style(AppFonts.mono, 14, 18, FontWeight.w500).copyWith(color: color);
}
