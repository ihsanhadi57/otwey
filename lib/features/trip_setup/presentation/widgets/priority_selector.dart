import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_segmented.dart';
import '../../domain/plan_pin.dart';

/// Prioritas tujuan (segmented navy) dengan penjelasan yang berubah sesuai pilihan.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({required this.selected, required this.onChanged, super.key});

  final PinPriority selected;
  final ValueChanged<PinPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hint = switch (selected) {
      PinPriority.wajib => AppCopy.wajibHint,
      PinPriority.penting => AppCopy.pentingHint,
      PinPriority.opsional => AppCopy.opsionalHint,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtwSegmented<PinPriority>(
          selected: selected,
          onChanged: onChanged,
          segments: const [
            OtwSegment(value: PinPriority.wajib, label: AppCopy.priorityWajib, icon: OtwIcon.lock),
            OtwSegment(value: PinPriority.penting, label: AppCopy.priorityPenting),
            OtwSegment(value: PinPriority.opsional, label: AppCopy.priorityOpsional),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (selected == PinPriority.wajib) ...[
              OtwIconView(OtwIcon.lock, variant: OtwIconVariant.fill, size: 14, color: c.inkMuted),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(hint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
            ),
          ],
        ),
      ],
    );
  }
}
