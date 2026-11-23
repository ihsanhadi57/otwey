import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/config/app_config.dart';
import 'package:otwey/core/utils/geo.dart';
import 'package:otwey/core/utils/seed_csv.dart';
import 'package:otwey/features/planner/data/seed_schedule_repository.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';

import '../support/real_data.dart';

/// Pemeriksaan data yang biasanya baru ketahuan di lapangan: koordinat salah
/// tempat, jadwal kereta tidak nyambung, rute transum yang tidak masuk akal.
void main() {
  late RealData data;
  setUpAll(() => data = RealData.load());

  test('setiap tempat berada di kota yang tercatat dan jam bukanya masuk akal', () {
    final problems = <String>[];
    var withoutHours = 0;
    for (final p in data.places) {
      final c = AppConfig.cityCenter(p.city);
      final km = haversineKm(p.lat, p.lng, c.lat, c.lng);
      if (km > 40) problems.add('${p.name} ${km.round()} km dari pusat ${p.city}');
      if (p.visitMinutes < 15 || p.visitMinutes > 240) problems.add('${p.name} durasi ${p.visitMinutes} mnt');
      if (p.openingHours.isEmpty) withoutHours++;
      for (final h in p.openingHours) {
        if (h.dayOfWeek < 1 || h.dayOfWeek > 7) problems.add('${p.name} hari ${h.dayOfWeek}');
        if (h.close <= h.open) problems.add('${p.name} tutup ${h.close} sebelum buka ${h.open}');
        if (h.close - h.open < 60) problems.add('${p.name} buka kurang dari 1 jam');
      }
    }
    // ignore: avoid_print
    print('${data.places.length} tempat, $withoutHours tanpa jam buka (tidak pernah direkomendasikan)');
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('jadwal Whoosh berurutan dan durasi antar stasiun wajar', () {
    final problems = <String>[];
    for (final date in [DateTime(2026, 11, 23), DateTime(2026, 11, 29)]) {
      for (final t in SeedScheduleRepository.tripsFrom(data.seed, date: date)) {
        var last = -1;
        for (final s in t.stops) {
          for (final m in [s.arrival, s.departure]) {
            if (m == null) continue;
            if (m < last) problems.add('${t.trainNo} mundur di ${s.stationCode}');
            last = m;
          }
        }
        final (from, to) = t.direction == TripDirection.jakartaToBandung ? ('HLM', 'TGL') : ('TGL', 'HLM');
        final dep = t.departureFrom(from);
        final arr = t.arrivalAt(to);
        if (dep != null && arr != null && (arr - dep < 30 || arr - dep > 60)) {
          problems.add('${t.trainNo} $from-$to ${arr - dep} mnt');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('KA Feeder nyambung dengan Whoosh di Padalarang', () {
    final problems = <String>[];
    final date = DateTime(2026, 11, 23);
    final trips = SeedScheduleRepository.tripsFrom(data.seed, date: date);
    final byId = {for (final t in trips) t.id: t};
    final feeders = SeedScheduleRepository.feedersFrom(data.seed, trips, date: date);
    expect(feeders, isNotEmpty);
    for (final f in feeders) {
      final t = f.connectsTripId == null ? null : byId[f.connectsTripId];
      if (t == null) continue;
      if (f.originStationCode == 'PDL') {
        // Turun Whoosh lalu naik feeder.
        final arr = t.arrivalAt('PDL');
        if (arr == null) {
          problems.add('feeder ${f.id} terhubung ke ${t.trainNo} yang tidak berhenti di Padalarang');
        } else if (f.departure < arr || f.departure - arr > 45) {
          problems.add('feeder ${f.id} berangkat ${f.departure - arr} mnt setelah ${t.trainNo} tiba');
        }
      } else if (f.destinationStationCode == 'PDL') {
        final dep = t.departureFrom('PDL');
        if (dep == null) {
          problems.add('feeder ${f.id} terhubung ke ${t.trainNo} yang tidak berhenti di Padalarang');
        } else if (f.arrival > dep || dep - f.arrival > 45) {
          problems.add('feeder ${f.id} tiba ${dep - f.arrival} mnt sebelum ${t.trainNo} berangkat');
        }
      }
      if (f.arrival <= f.departure) problems.add('feeder ${f.id} tiba sebelum berangkat');
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('jalur MRT, LRT, KRL: stasiun berurutan dengan jarak antar stasiun wajar', () {
    final st = parseCsv(File('tool/data/rail_stations.csv').readAsStringSync());
    final byLine = <String, List<(String, double, double)>>{};
    for (final r in st.rows) {
      byLine.putIfAbsent(st.cell(r, 'line_key'), () => []).add(
          (st.cell(r, 'station_name'), double.parse(st.cell(r, 'lat')), double.parse(st.cell(r, 'lng'))));
    }
    final problems = <String>[];
    for (final e in byLine.entries) {
      if (e.value.length < 2) problems.add('${e.key} kurang dari 2 stasiun');
      for (var i = 1; i < e.value.length; i++) {
        final a = e.value[i - 1];
        final b = e.value[i];
        final km = haversineKm(a.$2, a.$3, b.$2, b.$3);
        if (km < 0.3 || km > 7) problems.add('${e.key}: ${a.$1} ke ${b.$1} ${km.toStringAsFixed(1)} km');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('rute transum offline konsisten dan masuk akal', () {
    final json = jsonDecode(File('supabase/seed/derived/city_transit_jakarta.json').readAsStringSync()) as Map<String, dynamic>;
    final points = (json['points'] as List).cast<Map<String, dynamic>>();
    final problems = <String>[];
    var checked = 0;

    void route(Map<String, dynamic> r, String label, {double? km}) {
      checked++;
      final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
      final sum = steps.fold<num>(0, (a, s) => a + (s['minutes'] as num) + ((s['wait'] as num?) ?? 0));
      if (((r['minutes'] as num) - sum).abs() > steps.length) problems.add('$label: total ${r['minutes']} ≠ jumlah langkah $sum');
      if (!steps.any((s) => s['mode'] != 'walk')) problems.add('$label: tanpa kendaraan');
      if ((r['fare'] as num) < 0 || (r['fare'] as num) > 60000) problems.add('$label: tarif ${r['fare']}');
      for (final s in steps) {
        if ((s['minutes'] as num) < 0) problems.add('$label: menit negatif');
        if (s['mode'] == 'walk' && (s['minutes'] as num) > 25) problems.add('$label: jalan kaki ${s['minutes']} mnt');
      }
      for (var i = 1; i < steps.length; i++) {
        if (steps[i]['from'] != steps[i - 1]['to']) problems.add('$label: langkah tidak nyambung');
      }
      // Kecepatan rata rata total harus antara jalan kaki dan kereta.
      if (km != null && km > 2) {
        final kmh = km / ((r['minutes'] as num) / 60);
        if (kmh < 3 || kmh > 45) problems.add('$label: ${kmh.toStringAsFixed(1)} km/jam untuk ${km.toStringAsFixed(1)} km');
      }
    }

    for (final r in (json['routes'] as List).cast<Map<String, dynamic>>()) {
      final a = points[r['from'] as int];
      final b = points[r['to'] as int];
      final km = haversineKm(a['lat'] as double, a['lng'] as double, b['lat'] as double, b['lng'] as double);
      route(r, '${a['name']} → ${b['name']}', km: km);
    }
    for (final s in (json['access'] as List).cast<Map<String, dynamic>>()) {
      for (final a in (s['anchors'] as List).cast<Map<String, dynamic>>()) {
        if (a['to'] != null) route((a['to'] as Map).cast<String, dynamic>(), '${a['name']} → stasiun');
        if (a['from'] != null) route((a['from'] as Map).cast<String, dynamic>(), 'stasiun → ${a['name']}');
      }
    }
    // ignore: avoid_print
    print('$checked rute transum diperiksa, ${problems.length} masalah');
    expect(problems, isEmpty, reason: problems.take(30).join('\n'));
  });
}
