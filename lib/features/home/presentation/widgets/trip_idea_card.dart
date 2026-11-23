import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu ide trip sehari berlatar warna lembut kategori.
class TripIdeaCard extends StatelessWidget {
  const TripIdeaCard({
    required this.vibeCode,
    required this.title,
    required this.meta,
    required this.onTap,
    super.key,
  });

  final String vibeCode;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final bg = CategoryVisual.softBackground(c, vibeCode);
    return SizedBox(
      width: 220,
      height: 150,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OtwIconView(
                  CategoryVisual.icon(vibeCode),
                  variant: OtwIconVariant.fill,
                  size: 32,
                  color: CategoryVisual.tint(c, vibeCode),
                  knock: bg,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge?.copyWith(fontSize: 20, height: 24 / 20)),
                    Text(meta, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
