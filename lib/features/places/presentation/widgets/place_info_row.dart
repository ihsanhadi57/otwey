import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Satu baris info tempat: ikon, label kecil, nilai.
class PlaceInfoRow extends StatelessWidget {
  const PlaceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    super.key,
  });

  final OtwIcon icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtwIconView(icon, size: 22, color: c.ink),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
