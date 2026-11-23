import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu bawah di peta titik berangkat: alamat titik terpilih dan tombol pakai.
class OriginPointCard extends StatelessWidget {
  const OriginPointCard({
    required this.hasPoint,
    required this.resolving,
    required this.onConfirm,
    this.name,
    this.address,
    super.key,
  });

  final String? name;
  final String? address;
  final bool hasPoint;
  final bool resolving;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final title = !hasPoint
        ? AppCopy.tapMapForOrigin
        : resolving
            ? AppCopy.findingAddress
            : (name ?? address?.split(',').first.trim() ?? AppCopy.pointOnMap);
    final subtitle = hasPoint && !resolving ? address : null;
    return Material(
      color: c.surface200,
      elevation: 6,
      shadowColor: c.ink.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OtwIconView(OtwIcon.pin, size: 24, color: hasPoint ? c.brand : c.inkMuted),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: resolving ? null : onConfirm,
              child: const Text(AppCopy.useThisPoint),
            ),
          ],
        ),
      ),
    );
  }
}
