import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_bottom_bar.dart';
import '../../../../core/widgets/otw_press.dart';
import '../../../../core/widgets/otw_smooth_swap.dart';

/// Bar bawah Atur rencana: angka waktu luang + tombol Gas.
/// [freeMinutes] null berarti itinerary masih dihitung: angka diganti spinner
/// dan tombol Gas ditahan supaya tidak bisa ditekan sebelum data siap.
class PlanBottomBar extends StatelessWidget {
  const PlanBottomBar({required this.freeMinutes, required this.onGenerate, super.key});

  final int? freeMinutes;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final minutes = freeMinutes;

    return OtwBottomBar(
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppCopy.freeTimeLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted)),
              OtwSmoothSwap(
                swapKey: minutes == null,
                child: minutes == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: c.brand),
                        ),
                      )
                    : Text(
                        '± ${Clock.duration(minutes)}',
                        style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: minutes == null ? null : onGenerate,
              child: const Text(AppCopy.generateCta),
            ),
          ),
        ],
      ),
    );
  }
}