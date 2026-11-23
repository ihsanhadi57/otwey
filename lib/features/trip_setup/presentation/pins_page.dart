import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/step_scaffold.dart';
import '../domain/plan_pin.dart';
import 'trip_draft_notifier.dart';
import '../../../core/widgets/otw_press.dart';

class PinsPage extends ConsumerWidget {
  const PinsPage({super.key});

  static String priorityLabel(PinPriority p) => switch (p) {
        PinPriority.wajib => AppCopy.priorityWajib,
        PinPriority.penting => AppCopy.priorityPenting,
        PinPriority.opsional => AppCopy.priorityOpsional,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(tripDraftProvider).pins;

    return StepScaffold(
      title: AppCopy.pinsTitle,
      subtitle: AppCopy.pinsSubtitle,
      ctaLabel: pins.isEmpty ? AppCopy.skip : AppCopy.next,
      onCta: () => context.push(AppRoutes.vibes),
      child: ListView(
        children: [
          // TODO(hadi): ganti ListTile dengan widget PinCard sesuai design system.
          for (final p in pins)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: Text(
                p.isFixedTime
                    ? '${Clock.format(p.fixedStart!)} – ${Clock.format(p.fixedEnd!)}'
                    : '${AppCopy.flexibleTime} · ${Clock.duration(p.stayMinutes)}',
                style: TextStyle(color: context.colors.inkMuted),
              ),
              trailing: Text(priorityLabel(p.priority)),
            ),
          const OtwOutlinedButton.icon(
            // TODO(hadi): buka sheet Tambah tujuan (layar S5).
            onPressed: null,
            icon: Icon(Icons.add_rounded),
            label: Text(AppCopy.addPin),
          ),
        ],
      ),
    );
  }
}
