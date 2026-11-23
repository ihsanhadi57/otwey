import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Baris "Berangkat dari" yang membuka pemilih titik berangkat.
class OriginRow extends StatelessWidget {
  const OriginRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Material(
      color: c.surface100,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: OtwInkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
            child: Row(
              children: [
                OtwIconView(OtwIcon.pin, variant: OtwIconVariant.fill, size: 22, color: c.brand, knock: c.surface100),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppCopy.departFrom, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                      Text(label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(AppCopy.change, style: text.labelLarge?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
