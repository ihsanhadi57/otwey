import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../trip_setup/domain/vibe_catalog.dart';
import '../../../../core/widgets/otw_press.dart';

/// Filter vibes di atas peta Jelajah. Terpilih = navy penuh, ikon fill.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({required this.selected, required this.onChanged, super.key});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: VibeCatalog.vibes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (context, i) {
          final v = VibeCatalog.vibes[i];
          final on = v.code == selected;
          final fg = on ? c.surface200 : c.ink;
          return Semantics(
            selected: on,
            button: true,
            child: Material(
              color: on ? c.ink : c.surface200,
              shape: const StadiumBorder(),
              elevation: 2,
              shadowColor: c.ink.withValues(alpha: 0.2),
              child: OtwInkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onChanged(v.code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      OtwIconView(
                        CategoryVisual.icon(v.code),
                        variant: on ? OtwIconVariant.fill : OtwIconVariant.line,
                        size: 16,
                        color: on ? c.surface200 : CategoryVisual.tint(c, v.code),
                        knock: c.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(v.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
