import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/date_label.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../planner/domain/itinerary.dart';

/// Ringkasan trip berikutnya: blok tanggal, rute kota, jam jalan, jumlah tempat.
class UpcomingTripCard extends StatelessWidget {
  const UpcomingTripCard({required this.itinerary, required this.onTap, super.key});

  final Itinerary itinerary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: c.inkMuted);
    final d = itinerary.date;
    return OtwCard(
      style: OtwCardStyle.raised,
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: c.line))),
            child: Column(
              children: [
                Text(DateLabel.dayCode(d), style: text.bodySmall?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700)),
                Text('${d.day}', style: text.titleLarge?.copyWith(fontSize: 28, height: 32 / 28, fontWeight: FontWeight.w700)),
                Text(DateLabel.month(d), style: muted),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(itinerary.originCity, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    OtwIconView(OtwIcon.arrow, size: 16, color: c.inkMuted),
                    const SizedBox(width: 6),
                    Text(itinerary.destinationCity, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: DateLabel.isTomorrow(d, DateTime.now()) ? '${AppCopy.tomorrow} · ' : ''),
                    TextSpan(
                      text: AppCopy.leaveFromHome(Clock.format(itinerary.startTime)),
                      style: AppTypography.timeSm(color: c.inkMuted).copyWith(fontSize: 12),
                    ),
                  ]),
                  style: muted,
                ),
                Text(AppCopy.placesAndMeetings(itinerary.stops.length, itinerary.locked.length), style: muted),
              ],
            ),
          ),
          OtwIconView(OtwIcon.chevron, size: 22, color: c.inkMuted),
        ],
      ),
    );
  }
}
