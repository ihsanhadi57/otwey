import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Baris pengaturan dengan nilai dan chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.value,
    this.iconVariant = OtwIconVariant.line,
    this.iconColor,
    super.key,
  });

  final OtwIcon? icon;
  final OtwIconVariant iconVariant;
  final Color? iconColor;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return OtwInkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                OtwIconView(icon!, variant: iconVariant, size: 22, color: iconColor ?? c.inkMuted),
                const SizedBox(width: AppSpacing.s3),
              ],
              // Label dapat lebar alaminya; value yang memangkas diri dengan
              // elipsis supaya label tidak terlipat jadi dua baris.
              if (value == null)
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                )
              else ...[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: text.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.s1),
              OtwIconView(OtwIcon.chevron, size: 18, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
