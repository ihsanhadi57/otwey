import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_badge.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../domain/itinerary.dart';

/// Kartu tujuan Wajib yang terkunci di timeline.
class LockedCard extends StatelessWidget {
  const LockedCard({required this.entry, super.key});

  final LockedEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return OtwCard(
      borderColor: c.ink,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
              const OtwBadge(AppCopy.priorityWajib, tone: OtwBadgeTone.wajib),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${entry.purposeLabel} · '),
              TextSpan(
                text: '${Clock.format(entry.start)} – ${Clock.format(entry.end)}',
                style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 12),
              ),
              const TextSpan(text: ' · ${AppCopy.locked}'),
            ]),
            style: text.bodySmall?.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
