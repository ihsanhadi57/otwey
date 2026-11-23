import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/planner/domain/greedy_day_planner.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:otwey/features/trip_setup/domain/travel_mode.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';
import 'package:otwey/features/trip_setup/domain/trip_pace.dart';
import 'package:otwey/features/trip_setup/domain/vibe_catalog.dart';

import '../support/itinerary_invariants.dart';
import '../support/real_data.dart';

/// Pengganti uji lapangan: ribuan rencana dari data asli, setiap rencana
/// dijalani langkah demi langkah dan harus memenuhi semua aturan.
void main() {
  late RealData data;
  setUpAll(() => data = RealData.load());

  // Senin, Sabtu, Minggu (jadwal kereta beda di hari Minggu).
  final dates = [DateTime(2026, 11, 23), DateTime(2026, 11, 28), DateTime(2026, 11, 29)];
  final windows = [(6 * 60, 21 * 60), (8 * 60 + 30, 19 * 60), (10 * 60, 17 * 60)];

  OriginPoint origin(String id, double lat, double lng) =>
      OriginPoint(id: id, label: id, address: id, kind: OriginKind.other, lat: lat, lng: lng);

  final origins = <TripDirection, List<OriginPoint?>>{
    TripDirection.jakartaToBandung: [
      null, // mulai di stasiun
      origin('rawasari', -6.1890, 106.8690), // tanpa rel dekat
      origin('blok_m', -6.2440, 106.7990), // dekat MRT
      origin('kelapa_gading', -6.1600, 106.9080), // dekat LRT Jakarta
      origin('cibubur', -6.3700, 106.8950), // pinggir kota
    ],
    TripDirection.bandungToJakarta: [
      null,
      origin('dago', -6.8850, 107.6130),
      origin('buah_batu', -6.9480, 107.6330),
    ],
  };

  PlanPin meeting(TripDirection d) => d == TripDirection.jakartaToBandung
      ? const PlanPin(
          id: 'kantor',
          name: 'Kantor klien',
          lat: -6.8915,
          lng: 107.6107,
          purpose: PinPurpose.kerja,
          priority: PinPriority.wajib,
          fixedStart: 13 * 60,
          fixedEnd: 15 * 60,
        )
      : const PlanPin(
          id: 'kantor',
          name: 'Kantor klien',
          lat: -6.2250,
          lng: 106.8090,
          purpose: PinPurpose.kerja,
          priority: PinPriority.wajib,
          fixedStart: 13 * 60,
          fixedEnd: 15 * 60,
        );

  var plans = 0;
  var impossible = 0;
  var legs = 0;
  var transumLegs = 0;
  final failures = <String>[];
  final impossibleBy = <String, int>{};

  void check(TripDraft draft, String label) {
    final result = const GreedyDayPlanner().build(data.input(draft));
    final it = result.itinerary;
    if (it == null) {
      impossible++;
      final k = '${draft.pins.isNotEmpty ? 'pin' : 'tanpa pin'} ${draft.earliestDeparture ~/ 60}-${draft.latestReturn ~/ 60}';
      impossibleBy[k] = (impossibleBy[k] ?? 0) + 1;
      // Mustahil hanya boleh terjadi kalau memang ada tujuan Wajib atau
      // jendela waktunya terlalu sempit untuk naik kereta pulang pergi.
      if (draft.pins.isEmpty && draft.latestReturn - draft.earliestDeparture >= 9 * 60) {
        failures.add('$label: mustahil tanpa tujuan Wajib (${result.status})');
      }
      return;
    }
    plans++;
    expect(result.status, isNot(PlanStatus.impossible));
    expect(it.status, result.status);
    expect(it.droppedPinNames.length, result.droppedPinIds.length);
    final ls = it.entries.whereType<LegEntry>();
    legs += ls.length;
    transumLegs += ls.where((l) => l.recommended == LegMode.transum).length;
    for (final v in itineraryViolations(it, draft, data.places)) {
      failures.add('$label: $v');
    }
    // Rencana yang sama kalau user memaksa semua perpindahan jadi ojol atau
    // transum di layar hasil: tampilkan masalahnya juga (lihat test terpisah).
  }

  test('ribuan rencana dari data asli memenuhi semua aturan', () {
    for (final date in dates) {
      for (final dir in TripDirection.values) {
        for (final o in origins[dir]!) {
          for (final w in windows) {
            for (final vibe in VibeCatalog.vibes) {
              for (final pace in TripPace.values) {
                for (final mode in TravelMode.values) {
                  for (final withPin in [false, true]) {
                    final draft = TripDraft(
                      direction: dir,
                      travelDate: date,
                      earliestDeparture: w.$1,
                      latestReturn: w.$2,
                      origin: o,
                      pins: withPin ? [meeting(dir)] : const [],
                      tripTypeCode: vibe.code,
                      categoryCodes: [for (final s in VibeCatalog.subsOf(vibe.code)) s.code],
                      budget: 'sedang',
                      travelMode: mode,
                      maxStops: pace.maxStops,
                    );
                    check(draft,
                        '${date.weekday}/${dir.dbValue}/${o?.id ?? 'stasiun'}/${w.$1 ~/ 60}-${w.$2 ~/ 60}/${vibe.code}/${pace.name}/${mode.name}/${withPin ? 'pin' : '-'}');
                  }
                }
              }
            }
          }
        }
      }
    }
    // ignore: avoid_print
    print('$plans rencana, $impossible mustahil, $legs perpindahan ($transumLegs transum), '
        '${failures.length} pelanggaran');
    // ignore: avoid_print
    print('Mustahil per kelompok: $impossibleBy');
    if (failures.isNotEmpty) {
      final sample = failures.take(25).join('\n');
      fail('${failures.length} pelanggaran, contoh:\n$sample');
    }
    expect(plans, greaterThan(1000));
  });

  /// Skenario yang lebih kecil untuk uji pilihan moda per perpindahan.
  Iterable<TripDraft> sampleDrafts() sync* {
    for (final dir in TripDirection.values) {
      for (final o in origins[dir]!) {
        for (final w in windows.take(2)) {
          for (final vibe in VibeCatalog.vibes.take(3)) {
            for (final withPin in [false, true]) {
              yield TripDraft(
                direction: dir,
                travelDate: dates.first,
                earliestDeparture: w.$1,
                latestReturn: w.$2,
                origin: o,
                pins: withPin ? [meeting(dir)] : const [],
                tripTypeCode: vibe.code,
                categoryCodes: [for (final s in VibeCatalog.subsOf(vibe.code)) s.code],
                budget: 'sedang',
                maxStops: 4,
              );
            }
          }
        }
      }
    }
  }

  test('user mengganti moda satu perpindahan: jadwal disusun ulang dan tetap bisa dijalani', () {
    var switched = 0;
    final problems = <String>[];
    for (final draft in sampleDrafts()) {
      final it = const GreedyDayPlanner().build(data.input(draft)).itinerary;
      if (it == null) continue;
      for (final leg in it.legs.where((l) => l.hasTransum && l.hasPoints)) {
        final want = leg.recommended == LegMode.ojol ? LegMode.transum : LegMode.ojol;
        final key = legKey(leg.fromLat!, leg.fromLng!, leg.toLat!, leg.toLng!);
        final next = draft.copyWith(
          legModes: {...draft.legModes, key: want},
          keptPlaceIds: it.recommendedPlaceIds,
          maxStops: it.recommendedPlaceIds.length,
        );
        final again = const GreedyDayPlanner().build(data.input(next)).itinerary;
        if (again == null) {
          // Boleh mustahil hanya kalau ada tujuan Wajib yang jadi tidak terkejar.
          if (draft.pins.isEmpty) problems.add('${leg.destination}: jadi mustahil');
          continue;
        }
        switched++;
        final same = again.legs.where((l) =>
            l.hasPoints && legKey(l.fromLat!, l.fromLng!, l.toLat!, l.toLng!) == key);
        for (final l in same) {
          if (l.recommended != want) problems.add('${leg.destination}: moda pilihan tidak dipakai');
        }
        problems.addAll(itineraryViolations(again, next, data.places).map((v) => '${leg.destination}: $v'));
      }
    }
    // ignore: avoid_print
    print('$switched penggantian moda dijadwal ulang, ${problems.length} masalah');
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
    expect(switched, greaterThan(50));
  });

  test('trip tersimpan: legFits hanya mengizinkan moda yang tidak membuat telat', () {
    var allowed = 0;
    var refused = 0;
    final problems = <String>[];
    for (final draft in sampleDrafts()) {
      final it = const GreedyDayPlanner().build(data.input(draft)).itinerary;
      if (it == null) continue;
      for (final leg in it.legs) {
        for (final mode in LegMode.values) {
          if (!it.legFits(leg.id, mode)) {
            refused++;
            continue;
          }
          allowed++;
          final v = itineraryViolations(it, draft, data.places,
              modeOf: (l) => l.id == leg.id ? mode : l.recommended);
          problems.addAll(v.map((x) => '${leg.destination}/${mode.name}: $x'));
        }
      }
    }
    // ignore: avoid_print
    print('legFits: $allowed diizinkan, $refused ditolak, ${problems.length} masalah');
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });
}
