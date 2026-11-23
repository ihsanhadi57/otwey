import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_validate.dart';
import 'package:otwey/features/places/data/seed_place_repository.dart';
import 'package:otwey/features/places/domain/place.dart';
import 'package:otwey/features/planner/data/seed_access_route_repository.dart';
import 'package:otwey/features/planner/data/seed_fare_rule_repository.dart';
import 'package:otwey/features/planner/data/seed_schedule_repository.dart';
import 'package:otwey/features/planner/data/travel_time.dart';
import 'package:otwey/features/planner/domain/city_transit.dart';
import 'package:otwey/features/planner/domain/day_planner.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

/// Data asli dari supabase/seed (sama dengan mode offline aplikasi).
class RealData {
  RealData._(this.seed, this.jakarta, this.places);

  final SeedData seed;
  final CityTransitIndex jakarta;
  final List<Place> places;

  static RealData? _cache;

  static RealData load() {
    if (_cache != null) return _cache!;
    final files = <String, String>{};
    for (final name in seedFileNames) {
      files[name] = File('supabase/seed/$name.csv').readAsStringSync();
    }
    final seed = validateSeed(files);
    expect(seed.ok, isTrue, reason: seed.issues.join('\n'));
    final jakarta = CityTransitIndex.fromJson(
      jsonDecode(File('supabase/seed/derived/city_transit_jakarta.json').readAsStringSync()) as Map<String, dynamic>,
    );
    return _cache = RealData._(seed, jakarta, SeedPlaceRepository.placesFrom(seed));
  }

  /// Input planner persis seperti itineraryProvider (rute transum Jakarta
  /// dipakai di sisi mana pun Jakarta berada).
  PlannerInput input(TripDraft draft, {bool transit = true}) {
    final trips = SeedScheduleRepository.tripsFrom(seed, date: draft.travelDate);
    CityTransitIndex? of(String city) => transit && city == 'Jakarta' ? jakarta : null;
    return PlannerInput(
      draft: draft,
      outboundTrips: trips.where((t) => t.direction == draft.direction).toList(),
      returnTrips: trips.where((t) => t.direction == draft.direction.reversed).toList(),
      feeders: SeedScheduleRepository.feedersFrom(seed, trips, date: draft.travelDate),
      candidatePlaces: places.where((p) => p.city == draft.destinationCity).toList(),
      stations: SeedScheduleRepository.stationsFrom(seed),
      accessRoutes: SeedAccessRouteRepository.routesFrom(seed),
      fareRules: SeedFareRuleRepository.rulesFrom(seed),
      travelMinutes: estimateTravelMinutes(),
      cityTransit: of(draft.destinationCity),
      originTransit: of(draft.originCity),
    );
  }
}
