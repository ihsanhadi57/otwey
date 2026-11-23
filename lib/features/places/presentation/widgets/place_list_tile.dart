import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place.dart';
import 'heart_button.dart';

/// Baris tempat di daftar Jelajah dan Wishlist.
class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    required this.place,
    required this.saved,
    required this.onTap,
    required this.onToggleSaved,
    this.footer,
    super.key,
  });

  final Place place;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  /// Aksi tambahan di bawah kartu, misalnya "Masukin ke rencana".
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final code = place.categoryCodes.first;
    final today = place.openingHours.where((h) => h.dayOfWeek == DateTime.now().weekday);
    return OtwCard(
      style: OtwCardStyle.raised,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 14, AppSpacing.s1, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OtwIconView(CategoryVisual.icon(code), size: 28, color: CategoryVisual.tint(c, code)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(place.area ?? place.city, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                    if (today.isNotEmpty)
                      Text(AppCopy.openUntil(Clock.format(today.first.close)),
                          style: text.bodySmall?.copyWith(color: c.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              HeartButton(saved: saved, onPressed: onToggleSaved),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.s3),
            Padding(padding: const EdgeInsets.only(right: AppSpacing.s3), child: footer!),
          ],
        ],
      ),
    );
  }
}
