import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_segmented.dart';
import '../../domain/trip_pace.dart';

/// Tempo trip: preset Santai, Pas, Padat, plus stepper untuk angka custom.
class PaceSelector extends StatelessWidget {
  const PaceSelector({required this.maxStops, required this.onChanged, super.key});

  final int maxStops;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppCopy.pace, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.s2),
        OtwSegmented<TripPace?>(
          semanticLabel: AppCopy.pace,
          selected: TripPace.of(maxStops),
          onChanged: (p) => onChanged(p!.maxStops),
          segments: const [
            OtwSegment(value: TripPace.santai, label: AppCopy.paceSantai),
            OtwSegment(value: TripPace.pas, label: AppCopy.pacePas),
            OtwSegment(value: TripPace.padat, label: AppCopy.pacePadat),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(child: Text(AppCopy.maxStopsLabel, style: text.bodyMedium)),
            _StepButton(
              icon: OtwIcon.minus,
              tooltip: AppCopy.maxStopsLess,
              onPressed: maxStops > TripPace.minStops ? () => onChanged(maxStops - 1) : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$maxStops',
                textAlign: TextAlign.center,
                style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _StepButton(
              icon: OtwIcon.plus,
              tooltip: AppCopy.maxStopsMore,
              onPressed: maxStops < TripPace.maxStopsLimit ? () => onChanged(maxStops + 1) : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(AppCopy.paceHint(maxStops), style: text.bodySmall?.copyWith(color: c.inkMuted)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final OtwIcon icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: OtwIconView(icon, size: 18, color: enabled ? c.ink : c.inkMuted),
    );
  }
}
