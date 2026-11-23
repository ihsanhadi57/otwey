import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_validate.dart';
import 'package:otwey/features/places/data/seed_place_repository.dart';
import 'package:otwey/features/planner/data/seed_access_route_repository.dart';
import 'package:otwey/features/planner/data/seed_fare_rule_repository.dart';
import 'package:otwey/features/planner/data/seed_schedule_repository.dart';
import 'package:otwey/features/planner/data/travel_time.dart';
import 'package:otwey/features/planner/domain/day_planner.dart';
import 'package:otwey/features/planner/domain/greedy_day_planner.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

Itinerary _build(TripDraft draft) {
  final files = <String, String>{};
  for (final f in Directory('test/fixtures/planner_day').listSync().whereType<File>()) {
    files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
  }
  final data = validateSeed(files);
  expect(data.ok, isTrue, reason: data.issues.join('\n'));
  final stations = SeedScheduleRepository.stationsFrom(data);
  final trips = SeedScheduleRepository.tripsFrom(data, date: draft.travelDate);
  final feeders = SeedScheduleRepository.feedersFrom(data, trips);
  final places = SeedPlaceRepository.placesFrom(data);
  final result = const GreedyDayPlanner().build(PlannerInput(
    draft: draft,
    outboundTrips: trips.where((t) => t.direction == draft.direction).toList(),
    returnTrips: trips.where((t) => t.direction == draft.direction.reversed).toList(),
    feeders: feeders,
    candidatePlaces: places.where((p) => p.city == draft.destinationCity).toList(),
    stations: stations,
    accessRoutes: SeedAccessRouteRepository.routesFrom(data),
    fareRules: SeedFareRuleRepository.rulesFrom(data),
    travelMinutes: estimateTravelMinutes(),
  ));
  return result.itinerary!;
}

void main() {
  final date = DateTime(2026, 11, 16);
  const kantor = PlanPin(
    id: 'kantor',
    name: 'Kantor klien Dago',
    lat: -6.8915,
    lng: 107.6107,
    purpose: PinPurpose.kerja,
    priority: PinPriority.wajib,
    fixedStart: 13 * 60,
    fixedEnd: 15 * 60,
  );
  final toBandung = TripDraft(
    direction: TripDirection.jakartaToBandung,
    travelDate: date,
    earliestDeparture: 7 * 60,
    latestReturn: 21 * 60,
    origin: const OriginPoint(
      id: 'home', label: 'Rumah', address: 'Tebet Barat, Jakarta',
      kind: OriginKind.home, lat: -6.2455, lng: 106.8580,
    ),
    pins: const [kantor],
    tripTypeCode: 'kulineran',
    categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
    budget: 'murah',
  );

  test('dua arah selalu sampai rumah sebelum batas', () {
    final bandung = _build(toBandung);
    expect(bandung.homeArrival, lessThanOrEqualTo(bandung.latestReturn));
    expect(bandung.destinationCity, 'Bandung');

    final jakarta = _build(toBandung.copyWith(
      direction: TripDirection.bandungToJakarta,
      earliestDeparture: 6 * 60,
      pins: const [],
      tripTypeCode: 'budaya',
      categoryCodes: const ['sejarah_budaya', 'makanan_berat'],
      origin: const OriginPoint(
        id: 'home', label: 'Rumah', address: 'Coblong, Bandung',
        kind: OriginKind.home, lat: -6.9147, lng: 107.6098,
      ),
    ));
    expect(jakarta.homeArrival, lessThanOrEqualTo(jakarta.latestReturn));
    expect(jakarta.destinationCity, 'Jakarta');
  });

  test('getter model: spare, buffer pulang, dan stopByPlace konsisten', () {
    final it = _build(toBandung);
    expect(it.startTime, lessThan(it.homeArrival));
    expect(it.spareMinutes, it.latestReturn - it.homeArrival);
    expect(it.returnBuffer, isNotNull);
    expect(it.returnBuffer, greaterThanOrEqualTo(0));
    final firstStop = it.stops.first;
    expect(it.stopByPlace(firstStop.placeId)?.number, firstStop.number);
    expect(it.stopByPlace('tidak_ada'), isNull);
  });

  test('ongkos default mengikuti rekomendasi per leg', () {
    final it = _build(toBandung);
    final expected = it.legs.fold<int>(0, (s, l) => s + l.option(l.recommended).costRupiah);
    expect(it.totalCost(const {}), expected);
    final allOjol = {for (final l in it.legs) l.id: LegMode.ojol};
    expect(it.totalCost(allOjol), greaterThanOrEqualTo(expected));
  });

  test('tujuan Wajib tetap terkunci di itinerary', () {
    final it = _build(toBandung);
    expect(it.locked, isNotEmpty);
    expect(it.locked.first.title, 'Kantor klien Dago');
  });
}