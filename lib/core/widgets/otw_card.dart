import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_press.dart';

/// Gaya permukaan kartu.
enum OtwCardStyle {
  /// Garis tipis, untuk daftar dan kontrol.
  outlined,

  /// Bayangan lembut, untuk kartu yang perlu menonjol.
  raised,
}

/// Kartu dasar OTWEY: latar putih, sudut membulat, tap opsional.
class OtwCard extends StatelessWidget {
  const OtwCard({
    required this.child,
    this.style = OtwCardStyle.outlined,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.radius = AppRadius.md + 2,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    super.key,
  });

  final Widget child;
  final OtwCardStyle style;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: style == OtwCardStyle.outlined || borderColor != null
          ? BorderSide(color: borderColor ?? c.line, width: borderWidth)
          : BorderSide.none,
    );
    return OtwPressScale(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: style == OtwCardStyle.raised
              ? [
                  BoxShadow(
                    color: c.ink.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: color ?? c.surface200,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
