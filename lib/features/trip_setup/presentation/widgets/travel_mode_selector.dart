import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_choice_grid.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/travel_mode.dart';

/// Preferensi pindah antar tempat. Penjelasan opsi muncul di bawah grid.
class TravelModeSelector extends StatelessWidget {
  const TravelModeSelector({required this.selected, required this.onChanged, super.key});

  final TravelMode selected;
  final ValueChanged<TravelMode> onChanged;

  static String _hint(TravelMode m) => switch (m) {
        TravelMode.campur => AppCopy.travelCampurHint,
        TravelMode.ojol => AppCopy.travelOjolHint,
        TravelMode.transum => AppCopy.travelTransumHint,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppCopy.travelBetween, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.s2),
        OtwChoiceGrid<TravelMode>(
          selected: selected,
          onChanged: onChanged,
          choices: const [
            OtwChoice(value: TravelMode.campur, label: AppCopy.travelCampur, icon: OtwIcon.route),
            OtwChoice(value: TravelMode.ojol, label: AppCopy.travelOjol, icon: OtwIcon.ojol),
            OtwChoice(value: TravelMode.transum, label: AppCopy.travelTransum, icon: OtwIcon.bus),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '${_hint(selected)} ${AppCopy.travelChangeLater}',
          style: text.bodySmall?.copyWith(color: c.inkMuted, height: 17 / 12),
        ),
      ],
    );
  }
}
