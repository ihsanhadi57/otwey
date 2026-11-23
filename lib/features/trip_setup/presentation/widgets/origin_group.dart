import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/origin_point.dart';
import 'origin_option_tile.dart';

/// Grup daftar titik berangkat dengan judul kecil.
class OriginGroup extends StatelessWidget {
  const OriginGroup({
    required this.title,
    required this.origins,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final String title;
  final List<OriginPoint> origins;
  final String? selectedId;
  final ValueChanged<OriginPoint> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface200,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                for (var i = 0; i < origins.length; i++)
                  OriginOptionTile(
                    origin: origins[i],
                    selected: origins[i].id == selectedId,
                    showDivider: i < origins.length - 1,
                    onTap: () => onSelect(origins[i]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s1),
      ],
    );
  }
}
