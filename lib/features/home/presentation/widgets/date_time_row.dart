import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Dua field tanggal dan rentang jam di luar rumah. Keduanya membuka picker.
class DateTimeRow extends StatelessWidget {
  const DateTimeRow({
    required this.dateLabel,
    required this.timeLabel,
    required this.onDate,
    required this.onTime,
    super.key,
  });

  final String dateLabel;
  final String timeLabel;
  final VoidCallback onDate;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: _Field(
            icon: OtwIcon.calendar,
            label: AppCopy.date,
            value: Text(dateLabel, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            onTap: onDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Field(
            icon: OtwIcon.clock,
            label: AppCopy.hoursOut,
            value: Text(timeLabel, style: AppTypography.timeSm().copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            onTap: onTime,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value, required this.onTap});

  final OtwIcon icon;
  final String label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OtwInkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            OtwIconView(icon, size: 22, color: c.brand),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
                  value,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
