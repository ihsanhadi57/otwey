import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_check_row.dart';
import '../../domain/vibe_catalog.dart';

/// Daftar sub kategori dari vibes terpilih (pilih banyak).
class SubVibeChecklist extends StatelessWidget {
  const SubVibeChecklist({
    required this.vibe,
    required this.selectedCodes,
    required this.onToggle,
    super.key,
  });

  final TripVibe vibe;
  final List<String> selectedCodes;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final subs = VibeCatalog.subsOf(vibe.code);
    final count = subs.where((s) => selectedCodes.contains(s.code)).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface200,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 14, AppSpacing.s4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppCopy.subVibeQuestion(vibe.label),
                        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text(AppCopy.pickedCount(count), style: text.bodySmall?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            for (final s in subs)
              OtwCheckRow(
                icon: CategoryVisual.icon(s.code),
                label: s.label,
                description: s.description,
                checked: selectedCodes.contains(s.code),
                onChanged: (_) => onToggle(s.code),
              ),
          ],
        ),
      ),
    );
  }
}
