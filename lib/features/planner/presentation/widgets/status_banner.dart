import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Banner status rencana. Aman: hijau dengan centang. [warning]: kuning
/// dengan ikon info, untuk kabar yang perlu diperhatikan.
class StatusBanner extends StatelessWidget {
  const StatusBanner({required this.message, this.warning = false, super.key});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = warning ? c.sunTint : c.accentTint;
    final tone = warning ? c.ink : c.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s3),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          OtwIconView(warning ? OtwIcon.info : OtwIcon.done,
              variant: OtwIconVariant.fill, size: 22, color: tone, knock: tint, play: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }
}
