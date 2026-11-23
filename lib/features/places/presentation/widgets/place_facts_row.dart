import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Satu fakta ringkas tempat.
class PlaceFact {
  const PlaceFact(this.icon, this.label, this.value);

  final OtwIcon icon;
  final String label;
  final String value;
}

/// Tiga fakta ringkas tempat: jam buka, durasi, jarak.
class PlaceFactsRow extends StatelessWidget {
  const PlaceFactsRow({required this.facts, super.key});

  final List<PlaceFact> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surface200,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OtwIconView(facts[i].icon, size: 18, color: c.brand),
                  const SizedBox(height: AppSpacing.s1),
                  Text(facts[i].label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(facts[i].value, style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
