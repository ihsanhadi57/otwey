import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_badge.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/plan_pin.dart';
import '../../../../core/widgets/otw_press.dart';

/// Satu tujuan user di daftar rencana, dengan tombol hapus.
class PinTile extends StatelessWidget {
  const PinTile({required this.pin, required this.onRemove, super.key});

  final PlanPin pin;
  final VoidCallback onRemove;

  static String purposeLabel(PinPurpose p) => switch (p) {
        PinPurpose.kerja => AppCopy.purposeKerja,
        PinPurpose.janji => AppCopy.purposeJanji,
        PinPurpose.main => AppCopy.purposeMain,
        PinPurpose.lainnya => AppCopy.purposeLainnya,
      };

  static OtwIcon purposeIcon(PinPurpose p) => switch (p) {
        PinPurpose.kerja => OtwIcon.briefcase,
        PinPurpose.janji => OtwIcon.calendar,
        PinPurpose.main => OtwIcon.ferris,
        PinPurpose.lainnya => OtwIcon.pin,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final wajib = pin.priority == PinPriority.wajib;
    final time = pin.isFixedTime
        ? '${Clock.format(pin.fixedStart!)} – ${Clock.format(pin.fixedEnd!)}'
        : '${AppCopy.flexibleTimeShort} · ${Clock.duration(pin.durationMinutes!)}';
    return GestureDetector(
      onLongPress: onRemove,
      child: OtwCard(
        style: OtwCardStyle.raised,
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            OtwIconView(
              wajib ? OtwIcon.lock : purposeIcon(pin.purpose),
              variant: wajib ? OtwIconVariant.fill : OtwIconVariant.line,
              size: 26,
              color: c.ink,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pin.name, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${purposeLabel(pin.purpose)} · '),
                      TextSpan(text: time, style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 12)),
                    ]),
                    style: text.bodySmall?.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            OtwBadge(
              switch (pin.priority) {
                PinPriority.wajib => AppCopy.priorityWajib,
                PinPriority.penting => AppCopy.priorityPenting,
                PinPriority.opsional => AppCopy.priorityOpsional,
              },
              tone: wajib ? OtwBadgeTone.wajib : OtwBadgeTone.soft,
            ),
            OtwIconButton(
              tooltip: AppCopy.removePin,
              onPressed: onRemove,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: OtwIconView(OtwIcon.close, size: 18, color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
