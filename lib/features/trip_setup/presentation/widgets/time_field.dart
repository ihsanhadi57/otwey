import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Field jam yang membuka picker. Tidak pernah memunculkan keyboard.
class TimeField extends StatelessWidget {
  const TimeField({required this.label, required this.minutes, required this.onTap, super.key});

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = Clock.format(minutes);
    return Semantics(
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Material(
        color: c.surface100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: c.line),
        ),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
              child: Row(
                children: [
                  OtwIconView(OtwIcon.clock, size: 20, color: c.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
                        Text(value, style: AppTypography.time(color: c.ink).copyWith(fontSize: 18)),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: math.pi / 2,
                    child: OtwIconView(OtwIcon.chevron, size: 18, color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
