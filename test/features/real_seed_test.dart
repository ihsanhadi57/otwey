import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_validate.dart';
import 'package:otwey/features/places/data/seed_place_repository.dart';
import 'package:otwey/features/planner/data/seed_access_route_repository.dart';
import 'package:otwey/features/planner/data/seed_fare_rule_repository.dart';
import 'package:otwey/features/planner/data/seed_schedule_repository.dart';
import 'package:otwey/features/planner/data/travel_time.dart';
import 'package:otwey/features/planner/domain/city_transit.dart';
import 'package:otwey/features/planner/domain/day_planner.dart';
import 'package:otwey/features/planner/domain/greedy_day_planner.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:otwey/features/trip_setup/domain/travel_mode.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

/// Penjaga mode offline: CSV asli di supabase/seed harus selalu lolos validasi,
/// karena aplikasi membacanya saat Supabase tidak tersedia.
SeedData _realSeed() {
  final files = <String, String>{};
  for (final name in seedFileNames) {
    files[name] = File('supabase/seed/$name.csv').readAsStringSync();
  }
  final data = validateSeed(files);
  expect(data.ok, isTrue, reason: data.issues.join('\n'));
  return data;
}

PlannerInput _input(SeedData data, TripDraft draft) {
  final trips = SeedScheduleRepository.tripsFrom(data, date: draft.travelDate);
  final places = SeedPlaceRepository.placesFrom(data);
  return PlannerInput(
    draft: draft,
    outboundTrips: trips.where((t) => t.direction == draft.direction).toList(),
    returnTrips: trips.where((t) => t.direction == draft.direction.reversed).toList(),
    feeders: SeedScheduleRepository.feedersFrom(data, trips, date: draft.travelDate),
    candidatePlaces: places.where((p) => p.city == draft.destinationCity).toList(),
    stations: SeedScheduleRepository.stationsFrom(data),
    accessRoutes: SeedAccessRouteRepository.routesFrom(data),
    fareRules: SeedFareRuleRepository.rulesFrom(data),
    travelMinutes: estimateTravelMinutes(),
  );
}

void main() {
  test('CSV seed asli lolos validasi dan lengkap', () {
    final data = _realSeed();
    expect(data.stations.every((s) => s.lat != null && s.lng != null), isTrue);
    final trains = data.whoosh.map((w) => w.trainNo).toSet();
    expect(trains.length, 62);
    expect(data.feeders, isNotEmpty);
    expect(data.places.length, greaterThanOrEqualTo(22));
  });

  test('service_days: kereta Senin-Sabtu tidak muncul di hari Minggu', () {
    final data = _realSeed();
    final sunday = SeedScheduleRepository.tripsFrom(data, date: DateTime(2026, 11, 22));
    final monday = SeedScheduleRepository.tripsFrom(data, date: DateTime(2026, 11, 23));
    expect(sunday.any((t) => t.trainNo == 'G1003'), isFalse);
    expect(monday.any((t) => t.trainNo == 'G1003'), isTrue);
    expect(sunday.length, 56);
    expect(monday.length, 62);
  });

  test('Skenario demo PRD 12 jalan offline dengan data asli', () {
    final data = _realSeed();
    final draft = TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: DateTime(2026, 11, 25), // Rabu
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      origin: const OriginPoint(
        id: 'home',
        label: 'Rumah',
        address: 'Tebet Barat, Jakarta',
        kind: OriginKind.home,
        lat: -6.2455,
        lng: 106.8580,
      ),
      pins: const [
        PlanPin(
          id: 'kantor',
          name: 'Kantor klien Dago',
          lat: -6.8915,
          lng: 107.6107,
          purpose: PinPurpose.kerja,
          priority: PinPriority.wajib,
          fixedStart: 13 * 60,
          fixedEnd: 15 * 60,
        ),
      ],
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
      budget: 'murah',
      travelMode: TravelMode.campur,
    );
    final result = const GreedyDayPlanner().build(_input(data, draft));
    final it = result.itinerary;
    expect(it, isNotNull, reason: '$result');
    expect(it!.homeArrival, lessThanOrEqualTo(21 * 60));
    expect(it.locked.first.start, 13 * 60);

    // Peta hasil: mulai dari stasiun tiba, memuat tujuan terkunci, berkoordinat asli.
    expect(it.route.first.kind, RoutePointKind.station);
    expect(it.route.any((p) => p.kind == RoutePointKind.locked && p.lat == -6.8915), isTrue);
    final numbers = [for (final p in it.route) if (p.kind == RoutePointKind.stop) p.number];
    expect(numbers, [for (var i = 1; i <= numbers.length; i++) i]);
  });
  test('Data asli: tempo Pas maks 4 tempat, makan besar tidak beruntun, hapus menjaga urutan', () {
    final data = _realSeed();
    final draft = TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: DateTime(2026, 11, 25),
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      origin: const OriginPoint(
        id: 'home',
        label: 'Rumah',
        address: 'Tebet Barat, Jakarta',
        kind: OriginKind.home,
        lat: -6.2455,
        lng: 106.8580,
      ),
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
      budget: 'murah',
    );
    final before = const GreedyDayPlanner().build(_input(data, draft)).itinerary!;
    expect(before.recommendedPlaceIds.length, lessThanOrEqualTo(4));
    final meals = before.stops.where((s) => s.categoryCode == 'makanan_berat' || s.categoryCode == 'makanan_barat');
    for (final a in meals) {
      for (final b in meals) {
        if (a != b) expect((a.time - b.time).abs(), greaterThanOrEqualTo(180));
      }
    }

    final recs = before.recommendedPlaceIds;
    final kept = recs.skip(1).toList();
    final after = const GreedyDayPlanner()
        .build(_input(data, draft.copyWith(excludedPlaceIds: [recs.first], keptPlaceIds: kept, maxStops: kept.length)))
        .itinerary!;
    expect(after.recommendedPlaceIds, kept);
    expect(after.freeBlocks.last.beforeReturn, isTrue);
    expect(after.returnBuffer, greaterThanOrEqualTo(15));
  });
  test('Data asli ke Bandung: turun Padalarang lalu KA Feeder ke Stasiun Bandung', () {
    final data = _realSeed();
    final draft = TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: DateTime(2026, 11, 25),
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
      budget: 'murah',
    );
    final it = const GreedyDayPlanner().build(_input(data, draft)).itinerary!;
    final feeders = it.trains.where((t) => t.isFeeder).toList();
    expect(feeders, hasLength(2));
    expect(feeders.first.from, 'Stasiun Padalarang');
    expect(feeders.first.to, 'Stasiun Bandung');
    // Tanpa asal: mulai langsung di stasiun, tidak ada perpindahan ke stasiun.
    final start = it.entries.first as PointEntry;
    expect(start.title, contains('Stasiun Halim'));
    expect(it.entries[1], isA<TrainEntry>());
    expect(it.entries.whereType<PointEntry>().where((p) => p.kind == PointKind.arrive), hasLength(2));
  });

  test('Jakarta: rute transum offline dipakai untuk perpindahan antar tempat', () {
    final data = _realSeed();
    final index = CityTransitIndex.fromJson(
      jsonDecode(File('supabase/seed/derived/city_transit_jakarta.json').readAsStringSync()) as Map<String, dynamic>,
    );
    expect(index.isEmpty, isFalse);
    final draft = TripDraft(
      direction: TripDirection.bandungToJakarta,
      travelDate: DateTime(2026, 11, 25),
      earliestDeparture: 6 * 60,
      latestReturn: 21 * 60,
      tripTypeCode: 'kota',
      categoryCodes: const ['sejarah_budaya'],
      travelMode: TravelMode.transum,
    );
    final base = _input(data, draft);
    final input = PlannerInput(
      draft: base.draft,
      outboundTrips: base.outboundTrips,
      returnTrips: base.returnTrips,
      feeders: base.feeders,
      candidatePlaces: base.candidatePlaces,
      stations: base.stations,
      accessRoutes: base.accessRoutes,
      fareRules: base.fareRules,
      travelMinutes: base.travelMinutes,
      cityTransit: index,
    );
    final it = const GreedyDayPlanner().build(input).itinerary!;
    final legs = it.entries.whereType<LegEntry>().toList();
    final withTransit = legs.where((l) => l.hasTransum).toList();
    expect(withTransit, isNotEmpty);
    // Langkah transum menyebut halte atau stasiun, dan jam tiba memakai menit transum.
    expect(withTransit.first.steps.any((s) => s.kind != TransitKind.walk), isTrue);
    expect(withTransit.first.recommended, LegMode.transum);
  });

  test('Dari lokasi user ke Halim: lewat titik ujung transum terbaik', () {
    final data = _realSeed();
    final index = CityTransitIndex.fromJson(
      jsonDecode(File('supabase/seed/derived/city_transit_jakarta.json').readAsStringSync()) as Map<String, dynamic>,
    );
    final draft = TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: DateTime(2026, 11, 25),
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat'],
      travelMode: TravelMode.transum,
      // Dekat Stasiun MRT Blok M, bukan tempat di katalog.
      origin: const OriginPoint(
        id: 'current',
        label: 'Lokasi sekarang',
        address: 'Blok M',
        kind: OriginKind.current,
        lat: -6.2440,
        lng: 106.7990,
      ),
    );
    final base = _input(data, draft);
    final input = PlannerInput(
      draft: base.draft,
      outboundTrips: base.outboundTrips,
      returnTrips: base.returnTrips,
      feeders: base.feeders,
      candidatePlaces: base.candidatePlaces,
      stations: base.stations,
      accessRoutes: base.accessRoutes,
      fareRules: base.fareRules,
      travelMinutes: base.travelMinutes,
      originTransit: index,
    );
    final it = const GreedyDayPlanner().build(input).itinerary!;
    final legs = it.entries.whereType<LegEntry>().toList();
    final first = legs.first;
    expect(first.hasTransum, isTrue);
    expect(first.recommended, LegMode.transum);
    // Jalan kaki ke stasiun MRT terdekat, lalu naik kereta kota.
    expect(first.steps.first.kind, TransitKind.walk);
    expect(first.steps.any((s) => s.kind == TransitKind.rail), isTrue);
    expect(first.transum!.minutes, lessThan(90));
    // Pulang dari Halim ke lokasi user juga punya transum.
    expect(legs.last.hasTransum, isTrue);
  });

  test('Ojol di opsi transum hanya ke stasiun rel terdekat', () {
    final data = _realSeed();
    final index = CityTransitIndex.fromJson(
      jsonDecode(File('supabase/seed/derived/city_transit_jakarta.json').readAsStringSync()) as Map<String, dynamic>,
    );
    final draft = TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: DateTime(2026, 11, 22),
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat'],
      travelMode: TravelMode.transum,
      // Rawasari, Cempaka Putih: tidak ada stasiun rel dalam jarak jalan kaki.
      origin: const OriginPoint(
        id: 'current',
        label: 'Lokasi sekarang',
        address: 'Rawasari',
        kind: OriginKind.current,
        lat: -6.1890,
        lng: 106.8690,
      ),
    );
    final base = _input(data, draft);
    final input = PlannerInput(
      draft: base.draft,
      outboundTrips: base.outboundTrips,
      returnTrips: base.returnTrips,
      feeders: base.feeders,
      candidatePlaces: base.candidatePlaces,
      stations: base.stations,
      accessRoutes: base.accessRoutes,
      fareRules: base.fareRules,
      travelMinutes: base.travelMinutes,
      originTransit: index,
    );
    final first = const GreedyDayPlanner().build(input).itinerary!.entries.whereType<LegEntry>().first;
    expect(first.hasTransum, isTrue);
    // ignore: avoid_print
    print([for (final s in first.steps) '${s.kind.name}: ${s.text} ${s.corridor ?? ''}']);
    if (first.steps.first.kind == TransitKind.bus && first.steps.first.text.startsWith('Ojol')) {
      // Setelah ojol langsung naik kereta kota (tanpa jalan jauh dulu).
      final firstRide = first.steps.skip(1).firstWhere((s) => s.kind != TransitKind.walk);
      expect(firstRide.kind, TransitKind.rail);
    }
  });
}
