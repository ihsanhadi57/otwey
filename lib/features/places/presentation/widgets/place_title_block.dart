import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place.dart';
import 'google_place_info.dart';

/// Kategori, nama, dan area tempat.
class PlaceTitleBlock extends StatelessWidget {
  const PlaceTitleBlock({required this.place, required this.categoryLabel, super.key});

  final Place place;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final code = place.categoryCodes.first;
    final tint = CategoryVisual.tint(c, code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OtwIconView(CategoryVisual.icon(code), size: 16, color: tint),
            const SizedBox(width: 6),
            Text(categoryLabel, style: text.bodySmall?.copyWith(color: tint, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(place.name, style: text.headlineMedium?.copyWith(fontSize: 28, height: 34 / 28)),
        Text('${place.area ?? ''}${place.area == null ? '' : ', '}${place.city}',
            style: text.bodyMedium?.copyWith(color: c.inkMuted, fontSize: 14)),
        GooglePlaceInfo(place: place),
      ],
    );
  }
}
