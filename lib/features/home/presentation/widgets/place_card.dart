import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../places/domain/place.dart';
import '../../../places/presentation/widgets/heart_button.dart';

/// Kartu tempat di carousel beranda: ikon kategori, nama, info, tombol hati.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.place,
    required this.saved,
    required this.onTap,
    required this.onToggleSaved,
    this.width = 158,
    super.key,
  });

  final Place place;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final code = place.categoryCodes.first;
    final today = DateTime.now().weekday;
    final hours = place.openingHours.where((h) => h.dayOfWeek == today);
    return SizedBox(
      width: width,
      height: 168,
      child: Stack(
        children: [
          Positioned.fill(
            child: OtwCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OtwIconView(CategoryVisual.icon(code), size: 30, color: CategoryVisual.tint(c, code)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 19 / 15)),
                      const SizedBox(height: 3),
                      Text(place.area ?? place.city, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                      if (hours.isNotEmpty)
                        Text(AppCopy.openUntil(Clock.format(hours.first.close)),
                            style: text.bodySmall?.copyWith(color: c.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.s1,
            right: AppSpacing.s1,
            child: HeartButton(saved: saved, onPressed: onToggleSaved),
          ),
        ],
      ),
    );
  }
}
