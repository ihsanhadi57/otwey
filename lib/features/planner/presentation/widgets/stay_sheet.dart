import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_press.dart';

/// Pilihan lama kunjungan (menit).
const stayOptions = [30, 45, 60, 90, 120, 150, 180, 240];

/// Lembar pilih lama di satu tempat. Tiap opsi menampilkan jam selesainya.
/// Mengembalikan menit yang dipilih, atau null kalau ditutup.
Future<int?> showStaySheet(
  BuildContext context, {
  required String title,
  required int start,
  required int current,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.colors.surface100,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => _StaySheet(title: title, start: start, current: current),
  );
}

class _StaySheet extends StatelessWidget {
  const _StaySheet({required this.title, required this.start, required this.current});

  final String title;
  final int start;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final options = {...stayOptions, current}.toList()..sort();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppCopy.stayTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(title, style: text.bodyMedium?.copyWith(color: c.inkMuted)),
            const SizedBox(height: AppSpacing.s4),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.s2,
              crossAxisSpacing: AppSpacing.s2,
              childAspectRatio: 2.6,
              children: [
                for (final m in options) _StayOption(minutes: m, until: start + m, selected: m == current),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(AppCopy.stayHint, style: text.bodySmall?.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _StayOption extends StatelessWidget {
  const _StayOption({required this.minutes, required this.until, required this.selected});

  final int minutes;
  final int until;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final fg = selected ? c.onBrand : c.ink;
    return Material(
      color: selected ? c.ink : c.surface200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? c.ink : c.line),
      ),
      child: OtwInkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.pop(context, minutes),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Clock.duration(minutes), style: text.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              Text(
                AppCopy.stayUntil(Clock.format(until)),
                style: AppTypography.timeSm(color: selected ? fg : c.inkMuted).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
