import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Tombol bulat putih mengambang, khusus di atas peta supaya tetap terbaca.
class OtwRoundButton extends StatelessWidget {
  const OtwRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = OtwIconVariant.line,
    this.iconColor,
    this.size = 44,
    this.play = 0,
    super.key,
  });

  final OtwIcon icon;
  final String tooltip;
  final VoidCallback onPressed;
  final OtwIconVariant variant;
  final Color? iconColor;
  final double size;
  final int play;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: OtwPressScale(
          scale: 0.92,
          child: Material(
            color: c.surface200,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: c.ink.withValues(alpha: 0.3),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: OtwIconView(
                    icon,
                    variant: variant,
                    size: 22,
                    color: iconColor ?? c.ink,
                    play: play,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
