import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_header.dart';
import '../../planner/presentation/itinerary_provider.dart';
import 'trip_draft_notifier.dart';
import 'widgets/free_time_section.dart';
import 'widgets/pins_section.dart';
import 'widgets/plan_bottom_bar.dart';
import 'widgets/trip_basics_editor.dart';
import 'widgets/trip_summary_card.dart';

/// Atur rencana: tujuan pasti dan isi waktu luang dalam satu layar.
class PlanSetupPage extends ConsumerWidget {
  const PlanSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final asyncIt = ref.watch(itineraryProvider);
    final preparing = asyncIt.isLoading && !asyncIt.hasValue;
    final freeMinutes = preparing ? null : (asyncIt.value?.freeMinutes ?? 0);

    return Scaffold(
      appBar: const OtwHeader(title: AppCopy.planSetupTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s1, AppSpacing.screen, AppSpacing.s8),
        children: [
          TripSummaryCard(draft: draft, onEdit: () => showTripBasicsSheet(context)),
          const SizedBox(height: 28),
          const PinsSection(),
          const SizedBox(height: 28),
          FreeTimeSection(freeMinutes: freeMinutes),
        ],
      ),
      bottomNavigationBar: PlanBottomBar(
        freeMinutes: freeMinutes,
        onGenerate: () => context.push(AppRoutes.generating),
      ),
    );
  }
}
