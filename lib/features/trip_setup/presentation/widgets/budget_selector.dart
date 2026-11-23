import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_segmented.dart';

/// Budget: Hemat, Sedang, Sultan (nilai `price_range`).
class BudgetSelector extends StatelessWidget {
  const BudgetSelector({required this.selected, required this.onChanged, super.key});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppCopy.budget, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.s2),
        OtwSegmented<String>(
          semanticLabel: AppCopy.budget,
          selected: selected,
          onChanged: onChanged,
          segments: const [
            OtwSegment(value: 'murah', label: AppCopy.budgetHemat),
            OtwSegment(value: 'sedang', label: AppCopy.budgetSedang),
            OtwSegment(value: 'mahal', label: AppCopy.budgetSultan),
          ],
        ),
      ],
    );
  }
}
