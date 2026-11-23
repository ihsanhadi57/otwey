import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../domain/itinerary.dart';
import '../../../../core/widgets/otw_press.dart';

/// Blok waktu luang di timeline. Sebelum pulang, bisa diisi lagi atau dipakai
/// buat pulang lebih awal (planner sudah memastikan keduanya muat).
class FreeTimeCard extends StatelessWidget {
  const FreeTimeCard({
    required this.entry,
    this.earlierReturn,
    this.onFillMore,
    this.onReturnEarlier,
    super.key,
  });

  final FreeTimeEntry entry;

  /// Jam berangkat kereta pulang lebih awal, untuk label tombol.
  final int? earlierReturn;
  final VoidCallback? onFillMore;
  final VoidCallback? onReturnEarlier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final actions = [
      if (onFillMore != null)
        OtwOutlinedButton(onPressed: onFillMore, child: const Text(AppCopy.fillMore)),
      if (onReturnEarlier != null && earlierReturn != null)
        OtwOutlinedButton(
          onPressed: onReturnEarlier,
          child: Text(AppCopy.returnEarlier(Clock.format(earlierReturn!))),
        ),
    ];
    return OtwCard(
      style: OtwCardStyle.outlined,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppCopy.freeTimeBlock} · ${Clock.duration(entry.minutes)}',
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            entry.beforeReturn ? AppCopy.freeTimeBeforeReturn : AppCopy.freeTimeBeforeAgenda,
            style: text.bodySmall?.copyWith(color: c.inkMuted),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Wrap(spacing: AppSpacing.s2, runSpacing: AppSpacing.s2, children: actions),
          ],
        ],
      ),
    );
  }
}
