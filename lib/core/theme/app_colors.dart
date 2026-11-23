import 'package:material_ui/material_ui.dart';

/// Token warna. Sumber: docs/DESIGN_SYSTEM.md.
///
/// Akses di widget: `Theme.of(context).extension<AppColors>()!` atau `context.colors`.
/// Jangan menulis hex langsung di widget.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface100,
    required this.surface200,
    required this.surface300,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.brand,
    required this.brandStrong,
    required this.brandTint,
    required this.onBrand,
    required this.accent,
    required this.accentTint,
    required this.modeWhoosh,
    required this.modeFeeder,
    required this.modeWalk,
    required this.warning,
    required this.danger,
    required this.focusRing,
    required this.logoOrange,
    required this.sun,
    required this.sunTint,
    required this.info,
    required this.infoTint,
    required this.earth,
  });

  final Color surface100;
  final Color surface200;
  final Color surface300;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color brand;
  final Color brandStrong;
  final Color brandTint;
  final Color onBrand;
  final Color accent;
  final Color accentTint;
  final Color modeWhoosh;
  final Color modeFeeder;
  final Color modeWalk;
  final Color warning;
  final Color danger;
  final Color focusRing;

  /// Oranye cerah khusus logo, maskot, dan ilustrasi. Bukan untuk teks atau tombol.
  final Color logoOrange;

  /// Kuning matahari untuk latar ilustrasi, ikon aplikasi, dan aksen ceria.
  final Color sun;

  /// Latar lembut kuning untuk kartu tips dan ilustrasi Oti.
  final Color sunTint;

  /// Biru untuk kategori Kota dan koridor kereta (LRT, KA Feeder).
  final Color info;
  final Color infoTint;

  /// Cokelat untuk kategori Belanja dan Ngopi.
  final Color earth;

  static const light = AppColors(
    surface100: Color(0xFFFBF7F2),
    surface200: Color(0xFFFFFFFF),
    surface300: Color(0xFFF1EBE3),
    line: Color(0xFFE6DED3),
    lineStrong: Color(0xFF8A8576),
    ink: Color(0xFF1B1F3B),
    inkMuted: Color(0xFF5B5F78),
    brand: Color(0xFFC93E17),
    brandStrong: Color(0xFFA8320F),
    brandTint: Color(0xFFFCE3D8),
    onBrand: Color(0xFFFFFFFF),
    accent: Color(0xFF1F7A55),
    accentTint: Color(0xFFE8F5EE),
    modeWhoosh: Color(0xFF1B1F3B),
    modeFeeder: Color(0xFF5A8AE6),
    modeWalk: Color(0xFFA7AABB),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB42318),
    focusRing: Color(0xFFC93E17),
    logoOrange: Color(0xFFFF6B2C),
    sun: Color(0xFFFFC83D),
    sunTint: Color(0xFFFFF1C9),
    info: Color(0xFF2E4FA3),
    infoTint: Color(0xFFE7ECFB),
    earth: Color(0xFF8A5A00),
  );

  static const dark = AppColors(
    surface100: Color(0xFF12142A),
    surface200: Color(0xFF1B1E38),
    surface300: Color(0xFF252948),
    line: Color(0xFF2C3052),
    lineStrong: Color(0xFF6F7396),
    ink: Color(0xFFF4EFE8),
    inkMuted: Color(0xFFA9ACC4),
    brand: Color(0xFFFF7A4D),
    brandStrong: Color(0xFFFF9A75),
    brandTint: Color(0xFF3A2230),
    onBrand: Color(0xFF12142A),
    accent: Color(0xFF4CC38A),
    accentTint: Color(0xFF15332A),
    modeWhoosh: Color(0xFFC3CAFF),
    modeFeeder: Color(0xFF5B86E5),
    modeWalk: Color(0xFF565A78),
    warning: Color(0xFFF5A524),
    danger: Color(0xFFFF6B5E),
    focusRing: Color(0xFFFF7A4D),
    logoOrange: Color(0xFFFF6B2C),
    sun: Color(0xFFFFC83D),
    sunTint: Color(0xFF3A321A),
    info: Color(0xFF9DB2FF),
    infoTint: Color(0xFF1E2647),
    earth: Color(0xFFE0B25A),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      surface100: mix(surface100, other.surface100),
      surface200: mix(surface200, other.surface200),
      surface300: mix(surface300, other.surface300),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      brand: mix(brand, other.brand),
      brandStrong: mix(brandStrong, other.brandStrong),
      brandTint: mix(brandTint, other.brandTint),
      onBrand: mix(onBrand, other.onBrand),
      accent: mix(accent, other.accent),
      accentTint: mix(accentTint, other.accentTint),
      modeWhoosh: mix(modeWhoosh, other.modeWhoosh),
      modeFeeder: mix(modeFeeder, other.modeFeeder),
      modeWalk: mix(modeWalk, other.modeWalk),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      focusRing: mix(focusRing, other.focusRing),
      logoOrange: mix(logoOrange, other.logoOrange),
      sun: mix(sun, other.sun),
      sunTint: mix(sunTint, other.sunTint),
      info: mix(info, other.info),
      infoTint: mix(infoTint, other.infoTint),
      earth: mix(earth, other.earth),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
