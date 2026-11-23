import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Tiga angka ringkas: waktu luang, ongkos jalan, sampai rumah.
class ResultStatsRow extends StatelessWidget {
  const ResultStatsRow({
    required this.freeTime,
    required this.cost,
    required this.homeArrival,
    super.key,
  });

  final String freeTime;
  final String cost;
  final String homeArrival;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: AppCopy.statFreeTime, value: freeTime)),
        const SizedBox(width: AppSpacing.s2),
        Expanded(child: _Stat(label: AppCopy.statCost, value: cost)),
        const SizedBox(width: AppSpacing.s2),
        Expanded(child: _Stat(label: AppCopy.statHome, value: homeArrival)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface200,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpacing.s1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
