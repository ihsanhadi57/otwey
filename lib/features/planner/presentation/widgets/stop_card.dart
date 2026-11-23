import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/itinerary.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu tempat di timeline. Tap untuk buka detail atau tukar tempat,
/// tombol silang untuk menghapusnya dari rencana.
class StopCard extends StatelessWidget {
  const StopCard({required this.stop, required this.onTap, this.onRemove, super.key});

  final StopEntry stop;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final tagColor = stop.optional ? c.inkMuted : c.brandStrong;
    return OtwCard(
      style: OtwCardStyle.raised,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 20 / 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    OtwIconView(CategoryVisual.icon(stop.categoryCode), size: 16, color: tagColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        stop.categoryLabel,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: tagColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TimeInfo(start: stop.time, minutes: stop.minutes),
              ],
            ),
          ),
          if (onRemove != null)
            OtwIconButton(
              tooltip: AppCopy.removeStop,
              onPressed: onRemove,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: OtwIconView(OtwIcon.close, size: 18, color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// Jam kunjungan: rentang jam dan lama, dibungkus supaya tidak terpotong.
/// Mengubah lama dilakukan di halaman detail tempat.
class _TimeInfo extends StatelessWidget {
  const _TimeInfo({required this.start, required this.minutes});

  final int start;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OtwIconView(OtwIcon.clock, size: 15, color: c.inkMuted),
            const SizedBox(width: 5),
            Text(
              '${Clock.format(start)} – ${Clock.format(start + minutes)}',
              style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: c.brandTint, borderRadius: BorderRadius.circular(99)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              Clock.duration(minutes),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
