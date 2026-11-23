import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../trip_setup/presentation/widgets/trip_basics_editor.dart';
import '../../../trip_setup/presentation/trip_draft_notifier.dart';
import 'city_swap_row.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu rencana ala app travel: kota, titik berangkat, tanggal, jam, tombol rencanain.
class TripSearchCard extends ConsumerWidget {
  const TripSearchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final notifier = ref.read(tripDraftProvider.notifier);

    return OtwCard(
      style: OtwCardStyle.raised,
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CitySwapRow(from: draft.originCity, to: draft.destinationCity, onSwap: notifier.swapDirection),
          const SizedBox(height: 14),
          const TripBasicsEditor(),
          const SizedBox(height: 14),
          OtwFilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => context.push(AppRoutes.plan),
            child: const Text(AppCopy.planTrip),
          ),
        ],
      ),
    );
  }
}
