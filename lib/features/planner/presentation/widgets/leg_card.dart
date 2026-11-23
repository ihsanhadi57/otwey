import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/rupiah.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_mode_toggle.dart';
import '../../domain/itinerary.dart';
import '../../domain/leg_mode.dart';
import '../../domain/transit_route.dart';
import 'live_transit_panel.dart';
import 'live_transit_steps.dart';
import 'transit_step_row.dart';

/// Kartu perpindahan: tujuan, jarak, perkiraan tiba, lalu pilihan ojol atau
/// transum. Transum hanya muncul kalau datanya ada, dengan langkah per koridor.
class LegCard extends StatelessWidget {
  const LegCard({
    required this.leg,
    required this.mode,
    required this.onChanged,
    this.live,
    super.key,
  });

  final LegEntry leg;
  final LegMode mode;
  final ValueChanged<LegMode> onChanged;

  /// Rute transum langsung dari Google, kalau Supabase aktif dan rutenya ada.
  final TransitRoute? live;

  String _meta(LegOption o) =>
      '${Clock.duration(o.minutes)} · ${Rupiah.short(o.costRupiah, free: AppCopy.free)}';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final effective = leg.effective(mode);
    final km = leg.distanceKm == leg.distanceKm.roundToDouble()
        ? leg.distanceKm.toStringAsFixed(0)
        : leg.distanceKm.toStringAsFixed(1).replaceAll('.', ',');
    return OtwCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leg.destination,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$km km',
                      style: text.bodySmall?.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.accentTint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  AppCopy.arriveAround(Clock.format(leg.arrival(effective))),
                  style: AppTypography.timeSm(color: c.accent)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (leg.hasTransum)
            OtwModeToggle<LegMode>(
              semanticLabel: leg.destination,
              selected: effective,
              onChanged: onChanged,
              options: [
                OtwModeOption(
                  value: LegMode.ojol,
                  label: AppCopy.travelOjol,
                  icon: OtwIcon.ojol,
                  meta: _meta(leg.ojol),
                ),
                OtwModeOption(
                  value: LegMode.transum,
                  label: AppCopy.travelTransum,
                  icon: TransitStepRow.iconOf(leg.transumKind),
                  meta: _meta(leg.transum!),
                ),
              ],
            )
          else
            Row(
              children: [
                OtwIconView(OtwIcon.ojol, size: 20, color: c.ink),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  AppCopy.travelOjol,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  _meta(leg.ojol),
                  style: AppTypography.timeSm(color: c.inkMuted)
                      .copyWith(fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: effective == LegMode.transum && live != null
                ? LiveTransitSteps(route: live!)
                : effective == LegMode.transum
                ? Column(
                    children: [
                      for (var i = 0; i < leg.steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.s2),
                        TransitStepRow(step: leg.steps[i]),
                      ],
                    ],
                  )
                : Text(
                    leg.hasTransum ? AppCopy.ojolNote : AppCopy.noTransumData,
                    style: text.bodySmall?.copyWith(
                      color: c.inkMuted,
                      height: 17 / 12,
                    ),
                  ),
          ),
          if (live != null && effective == LegMode.ojol)
            LiveTransitPanel(
              route: live!,
              start: leg.start,
              plannedMinutes: leg.option(effective).minutes,
            ),
        ],
      ),
    );
  }
}
