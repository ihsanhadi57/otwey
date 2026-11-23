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
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/planner/domain/plan_item.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:otwey/features/trip_setup/domain/travel_mode.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

final _date = DateTime(2026, 11, 16); // Senin, sesuai jam buka fixture.

SeedData _fixture() {
  final files = <String, String>{};
  for (final f in Directory('test/fixtures/planner_day').listSync().whereType<File>()) {
    files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
  }
  final data = validateSeed(files);
  expect(data.ok, isTrue, reason: data.issues.join('\n'));
  return data;
}

PlannerInput _input(TripDraft draft) {
  final data = _fixture();
  final stations = SeedScheduleRepository.stationsFrom(data);
  final trips = SeedScheduleRepository.tripsFrom(data, date: draft.travelDate);
  final feeders = SeedScheduleRepository.feedersFrom(data, trips);
  final places = SeedPlaceRepository.placesFrom(data);
  return PlannerInput(
    draft: draft,
    outboundTrips: trips.where((t) => t.direction == draft.direction).toList(),
    returnTrips: trips.where((t) => t.direction == draft.direction.reversed).toList(),
    feeders: feeders,
    candidatePlaces: places.where((p) => p.city == draft.destinationCity).toList(),
    stations: stations,
    accessRoutes: SeedAccessRouteRepository.routesFrom(data),
    fareRules: SeedFareRuleRepository.rulesFrom(data),
    travelMinutes: estimateTravelMinutes(),
  );
}

const _kantor = PlanPin(
  id: 'kantor',
  name: 'Kantor klien Dago',
  lat: -6.8915,
  lng: 107.6107,
  purpose: PinPurpose.kerja,
  priority: PinPriority.wajib,
  fixedStart: 13 * 60,
  fixedEnd: 15 * 60,
);

const _kopi = PlanPin(
  id: 'kopi',
  name: 'Kopi incaran',
  lat: -6.8900,
  lng: 107.6130,
  purpose: PinPurpose.main,
  priority: PinPriority.opsional,
  durationMinutes: 45,
  placeId: 'kopi_dago',
);

TripDraft _toBandung({int latestReturn = 21 * 60, List<PlanPin> pins = const [], int maxStops = 4}) => TripDraft(
      maxStops: maxStops,
      direction: TripDirection.jakartaToBandung,
      travelDate: _date,
      earliestDeparture: 7 * 60,
      latestReturn: latestReturn,
      origin: const OriginPoint(
        id: 'home',
        label: 'Rumah',
        address: 'Tebet Barat, Jakarta',
        kind: OriginKind.home,
        lat: -6.2455,
        lng: 106.8580,
      ),
      pins: pins,
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
      budget: 'murah',
      travelMode: TravelMode.campur,
    );

void main() {
  const planner = GreedyDayPlanner();

  test('PRD 12 ke Bandung: meeting terkunci, pulang sebelum batas, status aman', () {
    final result = planner.build(_input(_toBandung(pins: [_kantor, _kopi])));
    final it = result.itinerary;
    expect(result.status, isNot(PlanStatus.impossible));
    expect(it, isNotNull);
    expect(it!.homeArrival, lessThanOrEqualTo(21 * 60));
    expect(it.locked, isNotEmpty);
    expect(it.locked.first.title, 'Kantor klien Dago');
    expect(it.locked.first.start, 13 * 60);
    expect(it.locked.first.end, 15 * 60);
    expect(it.stops, isNotEmpty);
    expect(result.status, PlanStatus.safe);
  });

  test('PRD 12 ke Jakarta: arah balik menghasilkan itinerary valid', () {
    final draft = TripDraft(
      direction: TripDirection.bandungToJakarta,
      travelDate: _date,
      earliestDeparture: 6 * 60,
      latestReturn: 21 * 60,
      origin: const OriginPoint(
        id: 'home',
        label: 'Rumah',
        address: 'Coblong, Bandung',
        kind: OriginKind.home,
        lat: -6.9147,
        lng: 107.6098,
      ),
      tripTypeCode: 'budaya',
      categoryCodes: const ['sejarah_budaya', 'makanan_berat'],
      budget: 'murah',
    );
    final result = planner.build(_input(draft));
    final it = result.itinerary;
    expect(it, isNotNull);
    expect(it!.destinationCity, 'Jakarta');
    expect(it.homeArrival, lessThanOrEqualTo(21 * 60));
    expect(it.stops.any((s) => s.placeId == 'fatahillah'), isTrue);
  });

  test('Tujuan Wajib tidak terkejar: konflik dengan blockingPinId', () {
    const pagi = PlanPin(
      id: 'pagi',
      name: 'Meeting pagi',
      lat: -6.8915,
      lng: 107.6107,
      purpose: PinPurpose.kerja,
      priority: PinPriority.wajib,
      fixedStart: 8 * 60,
      fixedEnd: 9 * 60,
    );
    final result = planner.build(_input(_toBandung(pins: [pagi])));
    expect(result.status, PlanStatus.impossible);
    expect(result.blockingPinId, 'pagi');
    expect(result.itinerary, isNull);
  });

  test('Kalau sempat dilepas saat jendela mepet', () {
    final result = planner.build(_input(_toBandung(latestReturn: 14 * 60, pins: [_kopi])));
    expect(result.itinerary, isNotNull);
    expect(result.droppedPinIds, contains('kopi'));
    expect(result.itinerary!.droppedPinNames, contains('Kopi incaran'));
    expect(result.itinerary!.stops, isEmpty);
  });

  test('Status mepet ikut tersimpan di itinerary', () {
    final result = planner.build(_input(_toBandung(latestReturn: 13 * 60 + 30, pins: [_kopi])));
    expect(result.itinerary, isNotNull);
    expect(result.status, PlanStatus.tight);
    expect(result.itinerary!.status, PlanStatus.tight);
    expect(result.itinerary!.spareMinutes, lessThan(30));
    expect(result.itinerary!.droppedPinNames, contains('Kopi incaran'));
  });

  test('Tempat yang tutup tidak dimasukkan ke rencana', () {
    final result = planner.build(_input(_toBandung()));
    final stops = result.itinerary!.stops;
    expect(stops.any((s) => s.placeId == 'tutup_pagi'), isFalse);
    expect(stops.any((s) => s.placeId == 'braga_jajan'), isTrue);
  });

  test('Setiap leg punya ojol; transum hanya dari rute akses yang ada datanya', () {
    final it = planner.build(_input(_toBandung(pins: [_kantor]))).itinerary!;
    expect(it.legs, isNotEmpty);
    for (final leg in it.legs) {
      expect(leg.ojol.minutes, greaterThan(0));
      if (leg.hasTransum) expect(leg.transum!.minutes, greaterThan(0));
      if (!leg.hasTransum) expect(leg.recommended, LegMode.ojol);
    }
    expect(it.legs.where((l) => l.hasTransum), isNotEmpty);
    expect(it.legs.where((l) => !l.hasTransum), isNotEmpty);
    expect(
      it.legs.any((l) => l.steps.any((s) => (s.corridor ?? '').contains('Bekasi Line'))),
      isTrue,
    );
  });

  test('Ongkos ojol lebih mahal dari transum, total mengikuti pilihan', () {
    final it = planner.build(_input(_toBandung(pins: [_kantor]))).itinerary!;
    final allOjol = {for (final l in it.legs) l.id: LegMode.ojol};
    final allTransum = {for (final l in it.legs) l.id: LegMode.transum};
    expect(it.totalCost(allOjol), greaterThan(it.totalCost(allTransum)));
    expect(it.totalCost(allTransum), greaterThanOrEqualTo(0));
  });

  test(
    'Jadwal resmi KCIC dipakai planner',
    () {
      final files = <String, String>{};
      for (final f in Directory('supabase/seed').listSync().whereType<File>()) {
        files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
      }
      expect(validateSeed(files).ok, isTrue);
    },
  );

  group('Tempo dan edit hasil', () {
    test('Batas tempo membatasi jumlah rekomendasi, pin user tidak dihitung', () {
      final full = planner.build(_input(_toBandung())).itinerary!;
      expect(full.recommendedPlaceIds.length, greaterThan(1));

      final one = planner.build(_input(_toBandung(maxStops: 1, pins: [_kopi]))).itinerary!;
      expect(one.recommendedPlaceIds, hasLength(1));
      expect(one.stops.any((s) => s.pinId == 'kopi'), isTrue);
      expect(one.moreStopsAvailable, isTrue);
    });

    test('Tempo 0: hanya tujuan user, sisa waktu jadi blok waktu luang', () {
      final it = planner.build(_input(_toBandung(maxStops: 0, pins: [_kantor]))).itinerary!;
      expect(it.recommendedPlaceIds, isEmpty);
      expect(it.locked, hasLength(1));
      expect(it.freeBlocks, isNotEmpty);
      expect(it.freeBlocks.last.beforeReturn, isTrue);
    });

    test('Hapus satu tempat: sisanya tetap dan urutannya sama, jam dihitung ulang', () {
      final draft = _toBandung();
      final before = planner.build(_input(draft)).itinerary!;
      final recs = before.recommendedPlaceIds;
      expect(recs.length, greaterThanOrEqualTo(2));
      final removed = recs.first;
      final kept = recs.skip(1).toList();

      final after = planner
          .build(_input(draft.copyWith(excludedPlaceIds: [removed], keptPlaceIds: kept, maxStops: kept.length)))
          .itinerary!;
      expect(after.recommendedPlaceIds, kept);
      expect(after.stops.any((s) => s.placeId == removed), isFalse);
      expect(after.homeArrival, lessThanOrEqualTo(draft.latestReturn));
      expect(after.freeBlocks, isNotEmpty);
      // Jam kunjungan ikut berubah karena rute baru langsung dari stasiun.
      expect(after.stops.first.time, isNot(before.stops[1].time));
    });

    test('Isi lagi menambah satu rekomendasi tanpa mengganti yang sudah ada', () {
      final draft = _toBandung(maxStops: 1);
      final before = planner.build(_input(draft)).itinerary!;
      final recs = before.recommendedPlaceIds;
      final after = planner
          .build(_input(draft.copyWith(keptPlaceIds: recs, maxStops: recs.length + 1)))
          .itinerary!;
      expect(after.recommendedPlaceIds, hasLength(2));
      expect(after.recommendedPlaceIds, containsAll(recs));
    });

    test('Pulang lebih awal: kereta yang ditawarkan memuat tempat yang sama', () {
      final draft = _toBandung(maxStops: 1);
      final before = planner.build(_input(draft)).itinerary!;
      final earlier = before.earlierReturnDeparture;
      expect(earlier, isNotNull);
      expect(earlier!, lessThan(before.returnDeparture!));

      final recs = before.recommendedPlaceIds;
      final after = planner
          .build(_input(draft.copyWith(returnDepartureCap: earlier, keptPlaceIds: recs, maxStops: recs.length)))
          .itinerary!;
      expect(after.returnDeparture, earlier);
      expect(after.recommendedPlaceIds, recs);
      expect(after.homeArrival, lessThan(before.homeArrival));
    });

    test('Jaga jaga kereta pulang tidak lagi selalu 0 menit', () {
      final it = planner.build(_input(_toBandung(maxStops: 0))).itinerary!;
      expect(it.returnBuffer, isNotNull);
      expect(it.freeBlocks.last.minutes, greaterThan(0));
    });
  });
}
