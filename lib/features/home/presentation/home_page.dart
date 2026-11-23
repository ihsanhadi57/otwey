import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_section_title.dart';
import '../../account/presentation/profile_provider.dart';
import '../../saved_trips/presentation/saved_trip_notifier.dart';
import '../../trip_setup/presentation/current_origin.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import 'widgets/home_header.dart';
import 'widgets/place_carousel.dart';
import 'widgets/trip_idea_carousel.dart';
import 'widgets/trip_search_card.dart';
import 'widgets/upcoming_trip_card.dart';
import '../../../core/widgets/otw_press.dart';

/// Tab Beranda.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Titik berangkat dari lokasi sekarang (izin lokasi diminta sekali).
    ref.watch(originBootstrapProvider);
    final profile = ref.watch(profileProvider);
    final saved = ref.watch(savedTripProvider).value;
    final city = ref.watch(tripDraftProvider.select((d) => d.destinationCity));

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header dan isi dalam satu anak list: kalau terpisah, bagian kartu
          // yang naik menumpuk ke header tidak bisa diketuk (hit test list
          // memakai posisi layout, bukan posisi setelah digeser).
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(name: profile.name),
              // Kartu rencana menumpuk 72 px ke header kuning. Semua isi di bawahnya ikut naik.
              Transform.translate(
                offset: const Offset(0, -72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                      ),
                      child: TripSearchCard(),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    if (saved != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          0,
                          AppSpacing.screen,
                          AppSpacing.s6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OtwSectionTitle(
                              AppCopy.nextTrip,
                              trailing: OtwTextButton(
                                onPressed: () => context.go(AppRoutes.trips),
                                child: const Text(AppCopy.seeAll),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s2),
                            UpcomingTripCard(
                              itinerary: saved.itinerary,
                              onTap: () => context.go(AppRoutes.trips),
                            ),
                          ],
                        ),
                      ),
                    PlaceCarousel(city: city),
                    const SizedBox(height: AppSpacing.s6),
                    const TripIdeaCarousel(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
