import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Judul tujuan berikutnya dan jam paling telat harus jalan.
class NextStopHeader extends StatelessWidget {
  const NextStopHeader({
    required this.title,
    required this.subtitle,
    required this.leaveBy,
    this.locked = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String leaveBy;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppCopy.nextUp,
                  style: text.bodySmall?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 4),
              Text(title, style: text.titleLarge?.copyWith(fontSize: 26)),
              Row(
                children: [
                  if (locked) ...[
                    OtwIconView(OtwIcon.lock, variant: OtwIconVariant.fill, size: 16, color: c.ink, knock: c.surface100),
                    const SizedBox(width: 6),
                  ],
                  Text(subtitle, style: text.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppCopy.leaveLatest, style: text.bodySmall?.copyWith(color: c.inkMuted)),
            Text(leaveBy, style: AppTypography.time(color: c.ink).copyWith(fontSize: 22)),
          ],
        ),
      ],
    );
  }
}
