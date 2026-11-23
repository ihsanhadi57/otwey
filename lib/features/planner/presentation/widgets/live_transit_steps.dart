import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/transit_route.dart';

/// Daftar langkah rute transum dari Google: jalan kaki, lalu tiap jalur
/// (MRT, LRT, TransJakarta, KRL) dengan warna jalur, halte naik dan turun.
class LiveTransitSteps extends StatelessWidget {
  const LiveTransitSteps({required this.route, super.key});

  final TransitRoute route;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < route.steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _StepRow(step: route.steps[i]),
        ],
        const SizedBox(height: 8),
        Text(AppCopy.liveTransitSource, style: text.labelSmall?.copyWith(color: c.inkMuted)),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final TransitLegStep step;

  static OtwIcon iconOf(TransitMode m) => switch (m) {
        TransitMode.walk => OtwIcon.walk,
        TransitMode.bus => OtwIcon.bus,
        TransitMode.subway || TransitMode.lightRail || TransitMode.rail || TransitMode.other => OtwIcon.train,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final meta = text.bodySmall?.copyWith(color: c.inkMuted);
    if (step.isWalk) {
      return Row(
        children: [
          OtwIconView(OtwIcon.walk, size: 20, color: c.inkMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(AppCopy.transitWalk(Clock.duration(step.minutes)), style: meta)),
        ],
      );
    }
    final argb = step.colorArgb;
    final lineColor = argb == null ? c.info : Color(argb);
    final onLine = lineColor.computeLuminance() > 0.5 ? c.ink : Colors.white;
    final badge = step.badge;
    final details = [
      if (step.stops != null) AppCopy.transitStops(step.stops!),
      Clock.duration(step.minutes),
      if (step.headsign != null) AppCopy.transitTowards(step.headsign!),
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtwIconView(iconOf(step.mode), size: 20, color: c.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: text.bodySmall?.copyWith(color: onLine, fontWeight: FontWeight.w700)),
                    ),
                  if (step.departAt != null)
                    Text(Clock.format(step.departAt!),
                        style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              if (step.from != null && step.to != null) ...[
                const SizedBox(height: 2),
                Text(AppCopy.transitRide(step.from!, step.to!),
                    style: text.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
              Text(details, style: meta),
            ],
          ),
        ),
      ],
    );
  }
}
