import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_validate.dart';
import 'package:otwey/features/places/data/local_wishlist_repository.dart';
import 'package:otwey/features/places/data/seed_place_repository.dart';
import 'package:otwey/features/places/domain/place.dart';
import 'package:otwey/features/planner/data/seed_access_route_repository.dart';
import 'package:otwey/features/planner/data/seed_fare_rule_repository.dart';
import 'package:otwey/features/planner/data/seed_schedule_repository.dart';
import 'package:otwey/features/planner/domain/access_route.dart';
import 'package:otwey/features/trip_setup/data/seed_origin_repository.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';

SeedData _fixture() {
  final files = <String, String>{};
  for (final f in Directory('test/fixtures/seed_valid').listSync().whereType<File>()) {
    files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
  }
  final data = validateSeed(files);
  expect(data.ok, isTrue, reason: data.issues.join('\n'));
  return data;
}

void main() {
  test('SeedPlaceRepository memetakan CSV ke Place lengkap dengan jam buka', () {
    final places = SeedPlaceRepository.placesFrom(_fixture());
    expect(places.length, 2);
    final braga = places.firstWhere((p) => p.id == 'braga_jajan');
    expect(braga.city, 'Bandung');
    expect(braga.categoryCodes, ['jajanan']);
    expect(braga.attributeCodes, ['spot_foto', 'budget_murah']);
    expect(braga.priceRange, PriceRange.murah);
    expect(braga.openingHours.length, 2);
    expect(braga.isOpen(1, 9 * 60, 10 * 60), isTrue);
    expect(braga.isOpen(3, 9 * 60, 10 * 60), isFalse);
  });

  test('SeedScheduleRepository memetakan stasiun, kereta, dan feeder', () {
    final data = _fixture();
    final stations = SeedScheduleRepository.stationsFrom(data);
    expect(stations.length, 3);
    expect(stations.first.code, 'HLM');
    expect(stations.first.lat, closeTo(-6.2155, 1e-9));

    final trips = SeedScheduleRepository.tripsFrom(data);
    expect(trips.length, 2);
    final g1001 = trips.firstWhere((t) => t.trainNo == 'G1001');
    expect(g1001.direction, TripDirection.jakartaToBandung);
    expect(g1001.departureFrom('HLM'), 9 * 60 + 25);
    expect(g1001.arrivalAt('PDL'), 10 * 60);

    final feeders = SeedScheduleRepository.feedersFrom(data, trips);
    expect(feeders.length, 2);
    expect(feeders.first.connectsTripId, g1001.id);
    expect(feeders.first.freeForWhoosh, isTrue);
    expect(feeders.first.departure, 10 * 60 + 10);
  });

  test('kereta di luar masa berlaku tidak ikut', () {
    final trips = SeedScheduleRepository.tripsFrom(
      _fixture(),
      date: DateTime(2026, 10, 1),
    );
    expect(trips, isEmpty);
  });

  test('SeedAccessRouteRepository mengelompokkan langkah per rute', () {
    final routes = SeedAccessRouteRepository.routesFrom(_fixture());
    expect(routes.length, 1);
    final r = routes.first;
    expect(r.code, 'cikoko_halim');
    expect(r.stationCode, 'HLM');
    expect(r.direction, AccessDirection.toStation);
    expect(r.steps.length, 2);
    expect(r.steps[1].corridor, 'Bekasi Line');
    expect(r.totalMinutes, 14);
    expect(r.totalFare, 5000);
  });

  test('SeedFareRuleRepository dan estimate tarif minimum', () {
    final rules = SeedFareRuleRepository.rulesFrom(_fixture());
    expect(rules.length, 1);
    final motor = rules.first;
    expect(motor.mode, 'two_wheeler');
    expect(motor.city, isNull);
    expect(motor.estimate(4), 20000);
    expect(motor.estimate(0), 10000);
  });

  test('titik berangkat mode seed = stasiun di kota itu, tanpa ETA karangan', () {
    final stations = SeedScheduleRepository.stationsFrom(_fixture());
    final origins = SeedOriginRepository.originsFrom(stations, 'Jakarta');
    expect(origins.length, 1);
    expect(origins.first.kind, OriginKind.station);
    expect(origins.first.label, 'Stasiun Halim');
    expect(origins.first.etaMinMinutes, isNull);
    expect(origins.first.etaMaxMinutes, isNull);
  });

  test('LocalWishlistRepository tambah dan hapus', () async {
    final repo = LocalWishlistRepository();
    expect(await repo.fetchIds(), isEmpty);
    await repo.add('braga_jajan');
    await repo.add('fatahillah');
    expect(await repo.fetchIds(), {'braga_jajan', 'fatahillah'});
    await repo.remove('braga_jajan');
    expect(await repo.fetchIds(), {'fatahillah'});
  });

  test(
    'CSV seed asli siap jadi data aplikasi',
    () {
      final files = <String, String>{};
      for (final f in Directory('supabase/seed').listSync().whereType<File>()) {
        files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
      }
      expect(validateSeed(files).ok, isTrue);
    },
    skip: 'TODO(hadi): supabase/seed masih template. Isi data bersumber lalu jalankan tool/seed_import.dart.',
  );
}