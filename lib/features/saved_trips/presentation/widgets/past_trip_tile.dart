import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_badge.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Trip yang sudah selesai.
class PastTripTile extends StatelessWidget {
  const PastTripTile({
    required this.from,
    required this.to,
    required this.meta,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String from;
  final String to;
  final String meta;
  final OtwIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return OtwCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          OtwIconView(icon, size: 24, color: c.earth),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(from, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    OtwIconView(OtwIcon.arrow, size: 14, color: c.inkMuted),
                    const SizedBox(width: 6),
                    Text(to, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                Text(meta, style: text.bodySmall?.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          const OtwBadge(AppCopy.done, tone: OtwBadgeTone.success),
        ],
      ),
    );
  }
}
