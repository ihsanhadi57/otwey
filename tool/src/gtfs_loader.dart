/// Memuat GTFS statis (zip) jadi halte, jalur, dan pola untuk [TransitRouter].
///
/// Hanya layanan hari kerja/harian yang masih berlaku dipakai. Headway diambil
/// dari frequencies.txt (rata rata jendela 08.00-20.00), kalau tidak ada dari
/// jumlah trip, kalau tidak ada juga 20 menit.
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:otwey/core/utils/seed_csv.dart';

import 'transit_router.dart';

class GtfsNetwork {
  GtfsNetwork(this.stops, this.patterns);

  final List<TransitStop> stops;
  final List<TransitPattern> patterns;
}

/// [stopOffset] = jumlah halte yang sudah ada sebelumnya (indeks global).
GtfsNetwork loadGtfs(
  List<int> zipBytes, {
  int stopOffset = 0,
  DateTime? on,
  String fareGroup = 'tj',
}) {
  final zip = ZipDecoder().decodeBytes(zipBytes);
  CsvTable table(String name) {
    final f = zip.findFile(name);
    if (f == null) return const CsvTable([], []);
    var text = utf8.decode(f.content as List<int>, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return parseCsv(text);
  }

  final day = on ?? DateTime.now();
  final ymd = day.year * 10000 + day.month * 100 + day.day;

  // Layanan yang berlaku hari kerja (Senin) dan masih dalam rentang tanggal.
  final cal = table('calendar.txt');
  final services = <String>{};
  for (final r in cal.rows) {
    final start = int.tryParse(cal.cell(r, 'start_date')) ?? 0;
    final end = int.tryParse(cal.cell(r, 'end_date')) ?? 0;
    if (ymd < start || ymd > end) continue;
    if (cal.cell(r, 'monday') == '1') services.add(cal.cell(r, 'service_id'));
  }

  // Tarif per rute.
  final fa = table('fare_attributes.txt');
  final price = <String, int>{};
  final transferable = <String, bool>{};
  for (final r in fa.rows) {
    final p = (double.tryParse(fa.cell(r, 'price')) ?? 3500).round();
    price[fa.cell(r, 'fare_id')] = p;
    transferable[fa.cell(r, 'fare_id')] = p <= 3500;
  }
  final fr = table('fare_rules.txt');
  final routeFare = <String, String>{};
  for (final r in fr.rows) {
    routeFare.putIfAbsent(fr.cell(r, 'route_id'), () => fr.cell(r, 'fare_id'));
  }

  final rt = table('routes.txt');
  final lines = <String, TransitLine>{};
  for (final r in rt.rows) {
    final id = rt.cell(r, 'route_id');
    final fareId = routeFare[id];
    final p = fareId == null ? 3500 : (price[fareId] ?? 3500);
    final desc = rt.cell(r, 'route_desc');
    final short = rt.cell(r, 'route_short_name');
    final long = rt.cell(r, 'route_long_name');
    lines[id] = TransitLine(
      key: 'tj_$id',
      name: desc.isEmpty ? 'TransJakarta $short' : '$desc $short · $long',
      short: short,
      mode: desc == 'BRT' ? RideMode.brt : RideMode.bus,
      fare: Fare(base: p),
      color: rt.cell(r, 'route_color').isEmpty ? null : rt.cell(r, 'route_color').toUpperCase(),
      fareGroup: (fareId == null || (transferable[fareId] ?? true)) ? fareGroup : null,
    );
  }

  final st = table('stops.txt');
  final stops = <TransitStop>[];
  final stopIndex = <String, int>{};
  for (final r in st.rows) {
    final lat = double.tryParse(st.cell(r, 'stop_lat'));
    final lng = double.tryParse(st.cell(r, 'stop_lon'));
    if (lat == null || lng == null) continue;
    final id = st.cell(r, 'stop_id');
    stopIndex[id] = stopOffset + stops.length;
    stops.add(TransitStop('tj:$id', st.cell(r, 'stop_name'), lat, lng));
  }

  final tr = table('trips.txt');
  final tripRoute = <String, String>{};
  for (final r in tr.rows) {
    if (!services.contains(tr.cell(r, 'service_id'))) continue;
    tripRoute[tr.cell(r, 'trip_id')] = tr.cell(r, 'route_id');
  }

  // Headway dari frequencies.
  final fq = table('frequencies.txt');
  final headway = <String, double>{};
  final weight = <String, double>{};
  for (final r in fq.rows) {
    final trip = fq.cell(r, 'trip_id');
    final a = _clock(fq.cell(r, 'start_time'));
    final b = _clock(fq.cell(r, 'end_time'));
    final h = (double.tryParse(fq.cell(r, 'headway_secs')) ?? 0) / 60;
    if (a == null || b == null || h <= 0) continue;
    final overlap = (b < 1200 ? b : 1200) - (a > 480 ? a : 480);
    if (overlap <= 0) continue;
    headway[trip] = (headway[trip] ?? 0) + h * overlap;
    weight[trip] = (weight[trip] ?? 0) + overlap;
  }

  final stt = table('stop_times.txt');
  final byTrip = <String, List<(int, String, double)>>{};
  for (final r in stt.rows) {
    final trip = stt.cell(r, 'trip_id');
    if (!tripRoute.containsKey(trip)) continue;
    final seq = int.tryParse(stt.cell(r, 'stop_sequence')) ?? 0;
    final t = _clock(stt.cell(r, 'departure_time')) ?? _clock(stt.cell(r, 'arrival_time'));
    if (t == null) continue;
    byTrip.putIfAbsent(trip, () => []).add((seq, stt.cell(r, 'stop_id'), t));
  }

  // Satu pola per (rute, urutan halte). Trip tanpa frekuensi menghitung headway dari jumlahnya.
  final patterns = <String, TransitPattern>{};
  final tripsPerPattern = <String, List<double>>{};
  final tripIds = byTrip.keys.toList()..sort();
  for (final trip in tripIds) {
    final rows = byTrip[trip]!..sort((a, b) => a.$1.compareTo(b.$1));
    final ids = <int>[];
    final mins = <double>[];
    for (final (_, sid, t) in rows) {
      final idx = stopIndex[sid];
      if (idx == null) continue;
      if (ids.isNotEmpty && ids.last == idx) continue;
      ids.add(idx);
      mins.add(t);
    }
    if (ids.length < 2) continue;
    final route = tripRoute[trip]!;
    final key = '$route|${ids.join(',')}';
    tripsPerPattern.putIfAbsent(key, () => []).add(mins.first);
    if (patterns.containsKey(key)) continue;
    final line = lines[route];
    if (line == null) continue;
    final base = mins.first;
    final rel = [for (final m in mins) m - base];
    // Jaga urutan menit naik, minimal 0,5 menit antar halte.
    for (var i = 1; i < rel.length; i++) {
      if (rel[i] < rel[i - 1] + 0.5) rel[i] = rel[i - 1] + 0.5;
    }
    final h = weight[trip] != null ? headway[trip]! / weight[trip]! : -1.0;
    patterns[key] = TransitPattern(line: line, stops: ids, minutes: rel, headway: h);
  }

  final out = <TransitPattern>[];
  for (final e in patterns.entries) {
    var h = e.value.headway;
    if (h <= 0) {
      final starts = tripsPerPattern[e.key]!..sort();
      if (starts.length >= 2) {
        h = (starts.last - starts.first) / (starts.length - 1);
      } else {
        h = 20;
      }
    }
    out.add(TransitPattern(line: e.value.line, stops: e.value.stops, minutes: e.value.minutes, headway: h));
  }
  return GtfsNetwork(stops, out);
}

/// "HH:MM:SS" (boleh > 24 jam) ke menit.
double? _clock(String s) {
  final p = s.split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final sec = p.length > 2 ? int.tryParse(p[2]) ?? 0 : 0;
  if (h == null || m == null) return null;
  return h * 60 + m + sec / 60;
}
