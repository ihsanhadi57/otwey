import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../places/presentation/places_provider.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../data/city_transit_repository.dart';
import '../data/seed_access_route_repository.dart';
import '../data/seed_fare_rule_repository.dart';
import '../data/seed_schedule_repository.dart';
import '../data/supabase_access_route_repository.dart';
import '../data/supabase_fare_rule_repository.dart';
import '../data/supabase_schedule_repository.dart';
import '../data/travel_time.dart';
import '../domain/day_planner.dart';
import '../domain/greedy_day_planner.dart';
import '../domain/itinerary.dart';

final dayPlannerProvider = Provider<DayPlanner>((ref) => const GreedyDayPlanner());

/// Itinerary dari rencana yang sedang disusun, lewat [DayPlanner] + repository.
/// Melempar [PlanConflictException] bila rencana tidak bisa dibuat (PRD 8.3).
final itineraryProvider = FutureProvider<Itinerary>((ref) async {
  final draft = ref.watch(tripDraftProvider);
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  final accessRepo = ref.watch(accessRouteRepositoryProvider);
  final fareRepo = ref.watch(fareRuleRepositoryProvider);

  final stations = await _fallback(scheduleRepo.fetchStations, SeedScheduleRepository().fetchStations);
  final outbound = await _fallback(
    () => scheduleRepo.fetchWhooshTrips(draft.direction, draft.travelDate),
    () => SeedScheduleRepository().fetchWhooshTrips(draft.direction, draft.travelDate),
  );
  final returns = await _fallback(
    () => scheduleRepo.fetchWhooshTrips(draft.direction.reversed, draft.travelDate),
    () => SeedScheduleRepository().fetchWhooshTrips(draft.direction.reversed, draft.travelDate),
  );
  final feeders = await _fallback(
    () => scheduleRepo.fetchFeeders(draft.travelDate),
    () => SeedScheduleRepository().fetchFeeders(draft.travelDate),
  );
  final accessRoutes = await _fallback(accessRepo.fetchAll, SeedAccessRouteRepository().fetchAll);
  final fareRules = await _fallback(fareRepo.fetchAll, SeedFareRuleRepository().fetchAll);

  final cityTransit = await ref.watch(cityTransitProvider(draft.destinationCity).future);
  final originTransit = await ref.watch(cityTransitProvider(draft.originCity).future);
  final allPlaces = await ref.watch(placesProvider.future);
  final candidates = allPlaces.where((p) => p.city == draft.destinationCity).toList();

  final input = PlannerInput(
    draft: draft,
    outboundTrips: outbound,
    returnTrips: returns,
    feeders: feeders,
    candidatePlaces: candidates,
    stations: stations,
    accessRoutes: accessRoutes,
    fareRules: fareRules,
    cityTransit: cityTransit,
    originTransit: originTransit,
    travelMinutes: estimateTravelMinutes(),
  );
  final result = ref.watch(dayPlannerProvider).build(input);
  final itinerary = result.itinerary;
  if (itinerary == null) throw PlanConflictException(result);
  return itinerary;
});

/// Supabase dulu; gagal atau lebih dari [_networkTimeout] → data seed bawaan,
/// supaya rencana tidak pernah menggantung karena jaringan.
Future<T> _fallback<T>(Future<T> Function() primary, Future<T> Function() backup) async {
  if (!Env.hasSupabase) return backup();
  try {
    return await primary().timeout(_networkTimeout);
  } catch (_) {
    return backup();
  }
}

const _networkTimeout = Duration(seconds: 8);