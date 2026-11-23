import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/date_label.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/trip_draft.dart';

/// Ringkasan rencana di atas layar Atur rencana. Tap untuk kembali mengubah.
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({required this.draft, required this.onEdit, super.key});

  final TripDraft draft;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: c.inkMuted);
    return OtwCard(
      style: OtwCardStyle.raised,
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(draft.originCity, style: text.titleLarge?.copyWith(fontSize: 20)),
                    const SizedBox(width: AppSpacing.s2),
                    OtwIconView(OtwIcon.arrow, size: 18, color: c.inkMuted),
                    const SizedBox(width: AppSpacing.s2),
                    Text(draft.destinationCity, style: text.titleLarge?.copyWith(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: AppSpacing.s1),
                if (draft.origin != null)
                  Row(
                    children: [
                      OtwIconView(OtwIcon.pin, variant: OtwIconVariant.fill, size: 14, color: c.brand),
                      const SizedBox(width: 6),
                      Expanded(child: Text(draft.origin!.shortLabel, style: muted)),
                    ],
                  ),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${DateLabel.short(draft.travelDate)} · '),
                    TextSpan(
                      text: '${Clock.format(draft.earliestDeparture)} – ${Clock.format(draft.latestReturn)}',
                      style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 12),
                    ),
                  ]),
                  style: muted,
                ),
              ],
            ),
          ),
          OtwIconView(OtwIcon.edit, size: 22, color: c.ink),
        ],
      ),
    );
  }
}
