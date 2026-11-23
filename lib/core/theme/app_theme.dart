import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandTint,
      onPrimaryContainer: c.brandStrong,
      secondary: c.accent,
      onSecondary: c.onBrand,
      secondaryContainer: c.accentTint,
      onSecondaryContainer: c.ink,
      error: c.danger,
      onError: c.onBrand,
      surface: c.surface100,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surface200,
      surfaceContainerLow: c.surface200,
      surfaceContainer: c.surface200,
      surfaceContainerHigh: c.surface300,
      surfaceContainerHighest: c.surface300,
      outline: c.lineStrong,
      outlineVariant: c.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.ui,
    );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
    );
    const buttonSize = Size.fromHeight(48);

    return base.copyWith(
      scaffoldBackgroundColor: c.surface100,
      // Tanpa percikan dan highlight abu: respons tekan lewat OtwPressScale.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: AppTypography.textTheme(base.textTheme, c.ink),
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface100,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: c.ink,
          backgroundColor: c.surface200,
          side: BorderSide(color: c.lineStrong),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
          foregroundColor: c.brandStrong,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
      ),
      cardTheme: CardThemeData(
        color: c.surface200,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface200,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    );
  }
}
