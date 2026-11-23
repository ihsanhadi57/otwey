import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_segmented.dart';
import '../../../core/widgets/otw_switch_row.dart';
import 'saved_trip_notifier.dart';
import 'widgets/past_trip_tile.dart';
import 'widgets/trip_ticket_card.dart';
import 'widgets/trips_empty_view.dart';
import '../../../core/widgets/otw_press.dart';

/// Tab Trip: trip yang akan datang dan yang sudah selesai.
class SavedTripsPage extends ConsumerStatefulWidget {
  const SavedTripsPage({super.key});

  @override
  ConsumerState<SavedTripsPage> createState() => _SavedTripsPageState();
}

class _SavedTripsPageState extends ConsumerState<SavedTripsPage> {
  bool _upcoming = true;
  bool _remind = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final asyncTrip = ref.watch(savedTripProvider);
    final trip = asyncTrip.value;
    // TODO(hadi): riwayat dari trx_plan berstatus selesai.
    const pastCount = 1;

    if (asyncTrip.isLoading) {
      return Scaffold(body: Center(child: Text(AppCopy.generating, style: text.bodyLarge)));
    }
    if (asyncTrip.hasError) {
      return Scaffold(
        body: OtwErrorView(
          onRetry: () => ref.invalidate(savedTripProvider),
          body: AppCopy.noData,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.s2, AppSpacing.s4),
              child: Row(
                children: [
                  Expanded(child: Text(AppCopy.tripTitle, style: text.titleLarge?.copyWith(fontSize: 26))),
                  OtwTextButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: OtwIconView(OtwIcon.plus, size: 20, color: c.brand),
                    label: const Text(AppCopy.newTrip),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: OtwSegmented<bool>(
                selected: _upcoming,
                onChanged: (v) => setState(() => _upcoming = v),
                segments: [
                  OtwSegment(value: true, label: AppCopy.upcoming(trip == null ? 0 : 1)),
                  OtwSegment(value: false, label: AppCopy.finished(pastCount)),
                ],
              ),
            ),
            Expanded(
              child: _upcoming && trip == null
                  ? const TripsEmptyView()
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      children: [
                        if (_upcoming && trip != null) ...[
                          TripTicketCard(
                            itinerary: trip.itinerary,
                            onSeePlan: () => context.push(AppRoutes.savedPlan),
                            onStart: () => context.push(AppRoutes.live),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          OtwSwitchRow(
                            icon: OtwIcon.bell,
                            label: AppCopy.remindMe,
                            description: AppCopy.remindMeHint,
                            value: _remind,
                            onChanged: (v) => setState(() => _remind = v),
                          ),
                        ],
                        if (!_upcoming)
                          PastTripTile(
                            from: 'Bandung',
                            to: 'Jakarta',
                            meta: 'Sab, 8 Nov · Kota Tua · 5 tempat',
                            icon: OtwIcon.city,
                            onTap: () {},
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
