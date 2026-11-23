import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/date_label.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../planner/domain/itinerary.dart';
import '../../../planner/presentation/widgets/stop_number_badge.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu tiket trip berikutnya. Fokus ke rencana hari itu, kereta cukup satu baris kecil.
class TripTicketCard extends StatelessWidget {
  const TripTicketCard({required this.itinerary, required this.onSeePlan, required this.onStart, super.key});

  final Itinerary itinerary;
  final VoidCallback onSeePlan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final mono = AppTypography.timeSm(color: c.ink).copyWith(fontSize: 13, fontWeight: FontWeight.w600);
    final firstStop = itinerary.stops.isEmpty ? null : itinerary.stops.first;
    final lock = itinerary.locked.isEmpty ? null : itinerary.locked.first;
    final shown = (firstStop != null ? 1 : 0) + (lock != null ? 1 : 0);
    final more = itinerary.stops.length + itinerary.locked.length - shown;
    final trains = itinerary.whooshTrains;

    return Container(
      decoration: BoxDecoration(
        color: c.surface200,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (DateLabel.isTomorrow(itinerary.date, DateTime.now()))
                      Text(AppCopy.tomorrow.toUpperCase(),
                          style: text.bodySmall?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                    const Spacer(),
                    Text(DateLabel.short(itinerary.date), style: text.labelLarge?.copyWith(color: c.inkMuted)),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    Text(itinerary.originCity, style: text.titleLarge?.copyWith(fontSize: 26)),
                    const SizedBox(width: 10),
                    OtwIconView(OtwIcon.arrow, size: 22, color: c.inkMuted),
                    const SizedBox(width: 10),
                    Text(itinerary.destinationCity, style: text.titleLarge?.copyWith(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    OtwIconView(OtwIcon.pin, variant: OtwIconVariant.fill, size: 16, color: c.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppCopy.leaveAt(Clock.format(itinerary.startTime), itinerary.originLabel),
                        style: text.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Perforation(color: c.surface100, line: c.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (firstStop != null)
                  _PlanLine(
                    leading: StopNumberBadge(firstStop.number, size: 22),
                    title: firstStop.title,
                    time: Text(Clock.format(firstStop.time), style: mono),
                  ),
                if (lock != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  _PlanLine(
                    leading: OtwIconView(OtwIcon.lock, variant: OtwIconVariant.fill, size: 18, color: c.ink),
                    title: lock.title,
                    time: Text(Clock.format(lock.start), style: mono),
                  ),
                ],
                if (more > 0) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      AppCopy.morePlaces(more, Clock.format(itinerary.homeArrival)),
                      style: text.bodySmall?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (trains.length >= 2) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      OtwIconView(OtwIcon.whoosh, size: 16, color: c.lineStrong),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        AppCopy.trainTimes(Clock.format(trains.first.departure), Clock.format(trains.last.departure)),
                        style: text.bodySmall?.copyWith(color: c.lineStrong),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    Expanded(
                      child: OtwOutlinedButton(onPressed: onSeePlan, child: const Text(AppCopy.seePlan)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OtwFilledButton.icon(
                        onPressed: onStart,
                        icon: OtwIconView(OtwIcon.navigate, variant: OtwIconVariant.fill, size: 18, color: c.onBrand, knock: c.brand),
                        label: const Text(AppCopy.startTrip),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.leading, required this.title, required this.time});

  final Widget leading;
  final String title;
  final Widget time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 22, child: Center(child: leading)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge)),
        time,
      ],
    );
  }
}

/// Garis sobekan tiket dengan dua lekukan di tepi.
class _Perforation extends StatelessWidget {
  const _Perforation({required this.color, required this.line});

  final Color color;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  for (var i = 0; i < box.maxWidth ~/ 10; i++)
                    Container(width: 6, height: 2, margin: const EdgeInsets.only(right: 4), color: line),
                ],
              ),
            ),
          ),
          Positioned(left: -10, child: _notch()),
          Positioned(right: -10, child: _notch()),
        ],
      ),
    );
  }

  Widget _notch() => Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
