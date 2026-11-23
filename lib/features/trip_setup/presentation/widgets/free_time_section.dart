import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_section_title.dart';
import '../../../../core/widgets/otw_smooth_swap.dart';
import '../../../../core/widgets/otw_switch_row.dart';
import '../trip_draft_notifier.dart';
import 'budget_selector.dart';
import 'pace_selector.dart';
import 'sub_vibe_checklist.dart';
import 'travel_mode_selector.dart';
import 'vibe_grid.dart';

/// Bagian "Isi waktu luang": vibes, sub kategori, tempo, budget, cara pindah, bawa bocil.
/// [freeMinutes] null berarti itinerary masih dihitung: hint diganti loading.
class FreeTimeSection extends ConsumerWidget {
  const FreeTimeSection({required this.freeMinutes, super.key});

  final int? freeMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final draft = ref.watch(tripDraftProvider);
    final notifier = ref.read(tripDraftProvider.notifier);
    final minutes = freeMinutes;
    final duration = minutes == null ? null : Clock.duration(minutes);
    final tooLight = (minutes ?? 0) >= 480 && draft.maxStops <= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtwSectionTitle(
          AppCopy.fillFreeTime,
          brand: true,
          subtitleWidget: OtwSmoothSwap(
            swapKey: duration == null,
            child: duration == null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.brand),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        AppCopy.calculatingFreeTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13),
                      ),
                    ],
                  )
                : _FreeTimeHint(duration: duration),
          ),
        ),
        const SizedBox(height: 14),
        VibeGrid(selected: draft.vibe.code, onChanged: notifier.setTripType),
        const SizedBox(height: 14),
        OtwSmoothSwap(
          swapKey: draft.vibe.code,
          child: SubVibeChecklist(vibe: draft.vibe, selectedCodes: draft.categoryCodes, onToggle: notifier.toggleCategory),
        ),
        const SizedBox(height: AppSpacing.s4),
        PaceSelector(maxStops: draft.maxStops, onChanged: notifier.setMaxStops),
        OtwSmoothSwap(
          swapKey: tooLight,
          child: tooLight
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s2),
                  child: Text(
                    AppCopy.paceTooLight(duration!, draft.maxStops),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w600),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.s4),
        BudgetSelector(selected: draft.budget ?? 'murah', onChanged: notifier.setBudget),
        const SizedBox(height: AppSpacing.s4),
        TravelModeSelector(selected: draft.travelMode, onChanged: notifier.setTravelMode),
        const SizedBox(height: AppSpacing.s4),
        OtwSwitchRow(
          icon: OtwIcon.family,
          label: AppCopy.withKids,
          value: draft.withKids,
          onChanged: notifier.setWithKids,
        ),
      ],
    );
  }
}

class _FreeTimeHint extends StatelessWidget {
  const _FreeTimeHint({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hint = AppCopy.freeTimeLeft(duration);
    final i = hint.indexOf(duration);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: hint.substring(0, i)),
        TextSpan(text: duration, style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        TextSpan(text: hint.substring(i + duration.length)),
      ]),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13),
    );
  }
}
