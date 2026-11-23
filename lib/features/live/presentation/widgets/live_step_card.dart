import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../planner/domain/leg_mode.dart';
import '../../../planner/presentation/widgets/leg_card.dart';
import '../../domain/live_steps.dart';

/// Kartu langkah aktif di mode jalan: jam, tujuan, dan cara ke sana.
class LiveStepCard extends StatelessWidget {
  const LiveStepCard({
    required this.step,
    required this.label,
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  final LiveStep step;

  /// "Sekarang" atau "Berikutnya".
  final String label;
  final LegMode mode;
  final ValueChanged<LegMode> onModeChanged;

  static OtwIcon iconOf(LiveStepKind k) => switch (k) {
        LiveStepKind.start => OtwIcon.home,
        LiveStepKind.station || LiveStepKind.arrive => OtwIcon.station,
        LiveStepKind.train => OtwIcon.whoosh,
        LiveStepKind.feeder => OtwIcon.train,
        LiveStepKind.stop => OtwIcon.pin,
        LiveStepKind.locked => OtwIcon.lock,
        LiveStepKind.free => OtwIcon.clock,
        LiveStepKind.home => OtwIcon.home,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final leg = step.leg;
    final time = step.endTime == null
        ? Clock.format(step.time)
        : '${Clock.format(step.time)} – ${Clock.format(step.endTime!)}';
    final title = step.kind == LiveStepKind.free ? AppCopy.liveFreeTitle : step.title;
    final hint = switch (step.kind) {
      LiveStepKind.train => AppCopy.liveTrainHint,
      LiveStepKind.feeder => AppCopy.liveFeederHint,
      _ => step.subtitle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtwCard(
          style: OtwCardStyle.raised,
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.brandTint, borderRadius: BorderRadius.circular(AppRadius.md)),
                alignment: Alignment.center,
                child: OtwIconView(iconOf(step.kind), size: 24, color: c.brandStrong),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        style: text.labelSmall?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(time, style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (hint != null && hint.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(hint, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (leg != null) ...[
          const SizedBox(height: AppSpacing.s3),
          LegCard(leg: leg, mode: mode, onChanged: onModeChanged),
        ] else if (step.walkMinutes != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              OtwIconView(OtwIcon.walk, size: 18, color: c.inkMuted),
              const SizedBox(width: 6),
              Text(AppCopy.liveWalk(step.walkMinutes!), style: text.labelLarge?.copyWith(color: c.inkMuted)),
            ],
          ),
        ],
      ],
    );
  }
}
