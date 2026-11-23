import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/date_label.dart';
import '../../../../core/widgets/otw_date_picker_sheet.dart';
import '../../../../core/widgets/otw_time_range_sheet.dart';
import '../../../home/presentation/widgets/date_time_row.dart';
import '../../../home/presentation/widgets/origin_row.dart';
import '../trip_draft_notifier.dart';
import '../../../../core/widgets/otw_press.dart';

/// Isian dasar trip: titik berangkat, tanggal, dan jam di luar rumah.
/// Dipakai di kartu Beranda dan lembar edit di Atur rencana.
class TripBasicsEditor extends ConsumerWidget {
  const TripBasicsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final notifier = ref.read(tripDraftProvider.notifier);

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showOtwDatePicker(
        context,
        initial: draft.travelDate,
        first: now,
        last: now.add(const Duration(days: AppConfig.maxDaysAhead)),
      );
      if (picked != null) notifier.setDate(picked);
    }

    Future<void> pickTimes() async {
      final r = await showOtwTimeRange(
        context,
        start: draft.earliestDeparture,
        end: draft.latestReturn,
      );
      if (r == null) return;
      notifier.setEarliestDeparture(r.start);
      notifier.setLatestReturn(r.end);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OriginRow(
          label: draft.origin?.shortLabel ?? AppCopy.originTitle,
          onTap: () => context.push(AppRoutes.origin),
        ),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: AppSpacing.s3),
        DateTimeRow(
          dateLabel: DateLabel.short(draft.travelDate),
          timeLabel: '${Clock.format(draft.earliestDeparture)} – ${Clock.format(draft.latestReturn)}',
          onDate: pickDate,
          onTime: pickTimes,
        ),
      ],
    );
  }
}

/// Lembar edit dari atas di Atur rencana: ubah asal, tanggal, dan jam tanpa
/// kembali ke Beranda. Perubahan langsung tersimpan ke draft.
Future<void> showTripBasicsSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppCopy.close,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => const _TopSheet(),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, -1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _TopSheet extends ConsumerWidget {
  const _TopSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(tripDraftProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: c.surface100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.screen, AppSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppCopy.editTripTitle, style: text.titleMedium),
                Text(
                  '${draft.originCity} → ${draft.destinationCity}',
                  style: text.bodySmall?.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpacing.s4),
                const TripBasicsEditor(),
                const SizedBox(height: AppSpacing.s4),
                OtwFilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppCopy.done),
                ),
                const SizedBox(height: AppSpacing.s2),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
