import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_choice_grid.dart';
import '../../domain/plan_pin.dart';
import 'pin_tile.dart';

/// "Buat apa ke sini?": 4 tile keperluan tujuan.
class PurposeGrid extends StatelessWidget {
  const PurposeGrid({required this.selected, required this.onChanged, super.key});

  final PinPurpose selected;
  final ValueChanged<PinPurpose> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppCopy.purposeQuestion, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.s2),
        OtwChoiceGrid<PinPurpose>(
          columns: 4,
          selected: selected,
          onChanged: onChanged,
          choices: [
            for (final p in PinPurpose.values)
              OtwChoice(value: p, label: PinTile.purposeLabel(p), icon: PinTile.purposeIcon(p)),
          ],
        ),
      ],
    );
  }
}
