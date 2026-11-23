import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Judul bagian. [brand] = Fredoka (judul besar form), selain itu heading UI.
class OtwSectionTitle extends StatelessWidget {
  const OtwSectionTitle(
    this.title, {
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.brand = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Dipakai kalau subjudul butuh gaya campuran (misalnya angka mono).
  final Widget? subtitleWidget;
  final Widget? trailing;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: brand ? text.titleLarge : text.titleMedium),
              ),
              if (subtitleWidget != null)
                subtitleWidget!
              else if (subtitle != null)
                Text(subtitle!, style: text.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
