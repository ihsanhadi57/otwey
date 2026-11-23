import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/step_scaffold.dart';
import 'trip_draft_notifier.dart';

class VibesPage extends ConsumerWidget {
  const VibesPage({super.key});

  // TODO(hadi): ambil dari tabel mst_trip_type. Sementara sama dengan seed.
  static const _tripTypes = <(String code, String name)>[
    ('kulineran', 'Kulineran'),
    ('alam', 'Healing'),
    ('budaya', 'Nostalgia Kota'),
    ('belanja', 'Mode Checkout'),
    ('keluarga', 'Family Trip'),
    ('campuran', 'Campur Aduk'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tripDraftProvider).tripTypeCode;
    final notifier = ref.read(tripDraftProvider.notifier);

    return StepScaffold(
      title: AppCopy.vibesTitle,
      ctaLabel: AppCopy.generateCta,
      onCta: () => context.push(AppRoutes.result),
      child: Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s2,
        children: [
          for (final (code, name) in _tripTypes)
            ChoiceChip(
              label: Text(name),
              selected: selected == code,
              onSelected: (_) => notifier.setTripType(code),
            ),
        ],
      ),
    );
  }
}
