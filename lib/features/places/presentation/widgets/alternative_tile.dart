import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place.dart';
import '../../../../core/widgets/otw_press.dart';

/// Tempat alternatif di slot yang sama, dengan tombol pilih.
class AlternativeTile extends StatelessWidget {
  const AlternativeTile({required this.place, required this.onPick, super.key});

  final Place place;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final code = place.categoryCodes.first;
    return OtwCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 10),
      child: Row(
        children: [
          OtwIconView(CategoryVisual.icon(code), size: 26, color: CategoryVisual.tint(c, code)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(place.area ?? place.city, style: text.bodySmall?.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          OtwOutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40), shape: const StadiumBorder()),
            onPressed: onPick,
            child: const Text(AppCopy.pick),
          ),
        ],
      ),
    );
  }
}
