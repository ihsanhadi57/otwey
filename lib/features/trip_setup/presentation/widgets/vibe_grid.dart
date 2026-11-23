import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_choice_grid.dart';
import '../../domain/vibe_catalog.dart';

/// Pilih satu vibes: grid 3 × 2 tanpa scroll.
class VibeGrid extends StatelessWidget {
  const VibeGrid({required this.selected, required this.onChanged, super.key});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OtwChoiceGrid<String>(
      selected: selected,
      onChanged: onChanged,
      choices: [
        for (final v in VibeCatalog.vibes)
          OtwChoice(
            value: v.code,
            label: v.label,
            icon: CategoryVisual.icon(v.code),
            tint: CategoryVisual.tint(c, v.code),
          ),
      ],
    );
  }
}
