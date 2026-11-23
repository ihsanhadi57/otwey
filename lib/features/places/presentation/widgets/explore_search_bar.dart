import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Baris atas Jelajah: kolom cari dan tombol filter, sama tinggi (52).
class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({
    required this.controller,
    required this.hint,
    required this.filterCount,
    required this.onChanged,
    required this.onFilter,
    super.key,
  });

  static const height = 52.0;

  final TextEditingController controller;
  final String hint;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: Material(
              color: c.surface200,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: c.ink.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.s4),
                  OtwIconView(OtwIcon.search, size: 20, color: c.inkMuted),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: text.bodyLarge,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: hint,
                        hintStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox(width: AppSpacing.s4)
                        : OtwIconButton(
                            tooltip: AppCopy.clearSearch,
                            onPressed: () {
                              controller.clear();
                              onChanged('');
                            },
                            icon: OtwIconView(OtwIcon.close, size: 18, color: c.inkMuted),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          backgroundColor: c.brand,
          offset: const Offset(-4, 4),
          child: Material(
            color: filterCount > 0 ? c.ink : c.surface200,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: c.ink.withValues(alpha: 0.3),
            child: OtwInkWell(
              customBorder: const CircleBorder(),
              onTap: onFilter,
              child: SizedBox.square(
                dimension: height,
                child: Center(
                  child: OtwIconView(
                    OtwIcon.filter,
                    size: 22,
                    color: filterCount > 0 ? c.onBrand : c.ink,
                    semanticLabel: AppCopy.filter,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
