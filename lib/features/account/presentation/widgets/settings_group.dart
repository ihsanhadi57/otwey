import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// Grup baris pengaturan dalam satu kartu, dengan judul kecil opsional.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(title!, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
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
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
