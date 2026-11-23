import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kolom cari mengambang di atas peta: tombol kembali, input, tombol cari.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.onChanged,
    this.hint = AppCopy.searchPlaceOrAddress,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 52,
      child: Material(
        color: c.surface200,
        elevation: 4,
        shadowColor: c.ink.withValues(alpha: 0.2),
        shape: const StadiumBorder(),
        child: Row(
          children: [
            OtwIconButton(
              tooltip: AppCopy.back,
              onPressed: () => context.pop(),
              icon: OtwIconView(OtwIcon.back, size: 22, color: c.ink),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
                  border: InputBorder.none,
                ),
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            OtwIconButton(
              tooltip: AppCopy.searchPlace,
              onPressed: onSubmit,
              icon: OtwIconView(OtwIcon.search, size: 20, color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
