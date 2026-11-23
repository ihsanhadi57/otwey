import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/step_scaffold.dart';
import 'trip_draft_notifier.dart';

class TimePage extends ConsumerWidget {
  const TimePage({super.key});

  Future<int?> _pick(BuildContext context, int initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final notifier = ref.read(tripDraftProvider.notifier);

    // TODO(hadi): input tanggal, titik asal, dan stasiun tujuan (PRD FR-02, FR-04, FR-05).
    return StepScaffold(
      title: AppCopy.departQuestion,
      ctaLabel: AppCopy.next,
      onCta: () => context.push(AppRoutes.pins),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppCopy.departQuestion),
            trailing: Text(
              Clock.format(draft.earliestDeparture),
              style: AppTypography.time(),
            ),
            onTap: () async {
              final m = await _pick(context, draft.earliestDeparture);
              if (m != null) notifier.setEarliestDeparture(m);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppCopy.returnQuestion),
            trailing: Text(
              Clock.format(draft.latestReturn),
              style: AppTypography.time(),
            ),
            onTap: () async {
              final m = await _pick(context, draft.latestReturn);
              if (m != null) notifier.setLatestReturn(m);
            },
          ),
        ],
      ),
    );
  }
}
