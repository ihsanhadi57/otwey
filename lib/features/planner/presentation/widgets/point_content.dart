import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// Isi baris titik (berangkat, stasiun, kereta, sampai rumah): judul dan keterangan.
class PointContent extends StatelessWidget {
  const PointContent({
    required this.title,
    this.subtitle,
    this.emphasis = true,
    this.subtitleColor,
    this.titleColor,
    super.key,
  });

  final Color? titleColor;

  final String title;
  final String? subtitle;

  /// False untuk baris kereta supaya tidak terlalu menonjol.
  final bool emphasis;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: text.bodyLarge?.copyWith(
                fontWeight: emphasis ? FontWeight.w700 : FontWeight.w600,
                color: titleColor,
              )),
          if (subtitle != null)
            Text(subtitle!, style: text.bodySmall?.copyWith(color: subtitleColor ?? c.inkMuted)),
        ],
      ),
    );
  }
}
