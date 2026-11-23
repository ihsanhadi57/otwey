/// Rute transum offline antar tempat (dan stasiun Whoosh) di satu kota.
///
/// Jalankan: dart run tool/city_transit.dart [--city=Jakarta] [--gtfs=path.zip]
///
/// Sumber:
/// * GTFS TransJakarta (Mobility Database id 1909), diunduh ke .dart_tool/otwey/
///   kalau --gtfs tidak diberikan.
/// * tool/data/rail_lines.csv + rail_stations.csv: MRT, LRT, KRL. Urutan stasiun
///   dari operator, koordinat dari OpenStreetMap, headway dan kecepatan estimasi.
/// * supabase/seed/place.csv dan station.csv: titik asal dan tujuan.
///
/// Hasil: `supabase/seed/derived/city_transit_<kota>.json`, dibaca aplikasi.
/// Data turunan: jangan diedit tangan, jalankan ulang tool ini.
library;

import 'dart:convert';
import 'dart:io';

import 'package:otwey/core/utils/seed_csv.dart';

import 'src/gtfs_loader.dart';
import 'src/transit_router.dart';

const _gtfsUrl = 'https://files.mobilitydatabase.org/mdb-1909/latest.zip';

/// Pasangan titik yang lebih dekat dari ini cukup jalan kaki atau ojol.
const _minPairKm = 1.0;

/// Rute transum lebih lama dari ini tidak disimpan.
const _maxMinutes = 150;

Future<void> main(List<String> args) async {
  String? arg(String name) =>
      args.where((a) => a.startsWith('--$name=')).map((a) => a.substring(name.length + 3)).firstOrNull;
  final city = arg('city') ?? 'Jakarta';
  if (city != 'Jakarta') {
    stderr.writeln('Belum ada data transum untuk $city.');
    exit(1);
  }

  final gtfsBytes = await _gtfs(arg('gtfs'));
  final today = DateTime.now();

  // Rel dulu (indeks kecil), lalu GTFS.
  final rail = _loadRail();
  final gtfs = loadGtfs(gtfsBytes, stopOffset: rail.stops.length, on: today);
  final stops = [...rail.stops, ...gtfs.stops];
  final patterns = [...rail.patterns, ...gtfs.patterns];
  stdout.writeln('Jaringan: ${stops.length} halte/stasiun, ${patterns.length} pola '
      '(${rail.patterns.length} rel, ${gtfs.patterns.length} bus).');

  final router = TransitRouter(stops, patterns, extraTransfers: _railTransfers(rail.stops));
  final points = _points(city);
  stdout.writeln('${points.length} titik di $city.');

  final routes = <Map<String, Object?>>[];
  var skipped = 0;
  final sw = Stopwatch()..start();
  for (var i = 0; i < points.length; i++) {
    final o = points[i];
    final targets = [for (final p in points) (lat: p.lat, lng: p.lng, name: p.name)];
    final found = router.routeMany((lat: o.lat, lng: o.lng, name: o.name), targets);
    for (var j = 0; j < points.length; j++) {
      if (i == j) continue;
      final r = found[j];
      final km = haversineKm(o.lat, o.lng, points[j].lat, points[j].lng);
      if (r == null || km < _minPairKm || r.minutes > _maxMinutes) {
        skipped++;
        continue;
      }
      routes.add(_routeJson(i, j, r));
    }
  }
  stdout.writeln('${routes.length} rute, $skipped pasangan dilewati (${sw.elapsed.inSeconds} dtk).');

  // Akses stasiun Whoosh dari titik mana pun: titik ujung (stasiun rel dan
  // halte BRT) dengan rute ke/dari stasiun. Aplikasi memilih ujung terbaik
  // dari lokasi user (jalan kaki atau ojol ke ujung, lalu rute ini).
  final anchors = _anchors(stops, patterns, rail.stops.length);
  final access = <Map<String, Object?>>[];
  for (var i = 0; i < points.length; i++) {
    final s = points[i];
    if (!s.isStation) continue;
    final sp = (lat: s.lat, lng: s.lng, name: s.name);
    final fromStation = router.routeMany(sp, [for (final a in anchors) (lat: a.lat, lng: a.lng, name: a.name)]);
    final list = <Map<String, Object?>>[];
    for (var k = 0; k < anchors.length; k++) {
      final a = anchors[k];
      if (haversineKm(a.lat, a.lng, s.lat, s.lng) < _minPairKm) continue;
      final to = router.routeMany((lat: a.lat, lng: a.lng, name: a.name), [sp]).single;
      final from = fromStation[k];
      if (to == null && from == null) continue;
      list.add({
        'name': a.name,
        'rail': a.id.startsWith('rail:'),
        'lat': a.lat,
        'lng': a.lng,
        if (to != null && to.minutes <= _maxMinutes) 'to': _routeBody(to),
        if (from != null && from.minutes <= _maxMinutes) 'from': _routeBody(from),
      });
    }
    access.add({'station': i, 'anchors': list});
    stdout.writeln('Akses ${s.name}: ${list.length} titik ujung.');
  }

  final out = File('supabase/seed/derived/city_transit_${city.toLowerCase()}.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(jsonEncode({
    'city': city,
    'generated': today.toIso8601String().substring(0, 10),
    'sources': [
      'GTFS TransJakarta (Mobility Database 1909)',
      'MRT/LRT/KRL: tool/data/rail_lines.csv (estimasi headway dan kecepatan)',
      'Koordinat stasiun: OpenStreetMap contributors (ODbL)',
    ],
    'points': [
      for (final p in points) {'key': p.key, 'name': p.name, 'lat': p.lat, 'lng': p.lng},
    ],
    'routes': routes,
    'access': access,
  }));
  stdout.writeln('Ditulis ke ${out.path} (${(out.lengthSync() / 1024).round()} KB).');
}

Map<String, Object?> _routeJson(int from, int to, FoundRoute r) => {'from': from, 'to': to, ..._routeBody(r)};

Map<String, Object?> _routeBody(FoundRoute r) => {
      'minutes': r.minutes.round(),
      'fare': r.fare,
      'steps': [
        for (final l in r.legs)
          {
            'mode': l.line?.mode.code ?? 'walk',
            if (l.line != null) 'line': l.line!.name,
            if (l.line != null) 'short': l.line!.short,
            if (l.line?.color != null) 'color': l.line!.color,
            'from': l.fromName,
            'to': l.toName,
            'minutes': l.minutes.round(),
            if (!l.isWalk) 'wait': l.wait.round(),
            if (!l.isWalk) 'stops': l.stops,
          },
      ],
    };

Future<List<int>> _gtfs(String? path) async {
  if (path != null) return File(path).readAsBytesSync();
  final cache = File('.dart_tool/otwey/transjakarta_gtfs.zip');
  if (cache.existsSync()) return cache.readAsBytesSync();
  stdout.writeln('Mengunduh GTFS TransJakarta ...');
  final client = HttpClient()..userAgent = 'otwey-seed-tool/0.1';
  try {
    final res = await (await client.getUrl(Uri.parse(_gtfsUrl))).close();
    if (res.statusCode != 200) throw HttpException('GTFS ${res.statusCode}');
    final bytes = <int>[];
    await for (final chunk in res) {
      bytes.addAll(chunk);
    }
    cache.parent.createSync(recursive: true);
    cache.writeAsBytesSync(bytes);
    return bytes;
  } finally {
    client.close();
  }
}

class _Rail {
  _Rail(this.stops, this.patterns);

  final List<TransitStop> stops;
  final List<TransitPattern> patterns;
}

_Rail _loadRail() {
  final lt = parseCsv(File('tool/data/rail_lines.csv').readAsStringSync());
  final st = parseCsv(File('tool/data/rail_stations.csv').readAsStringSync());
  final stops = <TransitStop>[];
  final index = <String, int>{};
  final byLine = <String, List<int>>{};
  final modeOf = {for (final r in lt.rows) lt.cell(r, 'line_key'): lt.cell(r, 'mode').toUpperCase()};
  for (final r in st.rows) {
    final name = st.cell(r, 'station_name');
    final lat = double.parse(st.cell(r, 'lat'));
    final lng = double.parse(st.cell(r, 'lng'));
    // Stasiun dengan nama dan titik sama dipakai bersama antar jalur.
    final id = 'rail:$name:${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final i = index.putIfAbsent(id, () {
      stops.add(TransitStop(id, 'Stasiun ${modeOf[st.cell(r, 'line_key')]} $name', lat, lng));
      return stops.length - 1;
    });
    byLine.putIfAbsent(st.cell(r, 'line_key'), () => []).add(i);
  }
  final patterns = <TransitPattern>[];
  for (final r in lt.rows) {
    final key = lt.cell(r, 'line_key');
    final ids = byLine[key];
    if (ids == null || ids.length < 2) continue;
    final speed = double.parse(lt.cell(r, 'speed_kmh'));
    final max = int.tryParse(lt.cell(r, 'fare_max'));
    final line = TransitLine(
      key: key,
      name: lt.cell(r, 'line_name'),
      short: lt.cell(r, 'line_short'),
      mode: RideMode.fromCode(lt.cell(r, 'mode')),
      fare: Fare(
        base: int.parse(lt.cell(r, 'fare_base')),
        baseKm: double.parse(lt.cell(r, 'fare_base_km')),
        perKm: int.parse(lt.cell(r, 'fare_per_km')),
        max: max,
      ),
    );
    final headway = double.parse(lt.cell(r, 'headway_min'));
    for (final seq in [ids, ids.reversed.toList()]) {
      final mins = <double>[0];
      for (var i = 1; i < seq.length; i++) {
        final a = stops[seq[i - 1]];
        final b = stops[seq[i]];
        // Waktu jalan dari jarak + 0,5 menit berhenti per stasiun.
        mins.add(mins.last + haversineKm(a.lat, a.lng, b.lat, b.lng) / speed * 60 + 0.5);
      }
      patterns.add(TransitPattern(line: line, stops: seq, minutes: mins, headway: headway));
    }
  }
  return _Rail(stops, patterns);
}

/// Pindah antar stasiun rel yang berdekatan tapi beda bangunan (misalnya MRT
/// dan LRT Dukuh Atas, KRL Sudirman). Jarak lebih longgar dari pindah halte bus.
List<(int, int, double)> _railTransfers(List<TransitStop> rail) {
  const km = 0.7;
  final out = <(int, int, double)>[];
  for (var a = 0; a < rail.length; a++) {
    for (var b = 0; b < rail.length; b++) {
      if (a == b) continue;
      final d = haversineKm(rail[a].lat, rail[a].lng, rail[b].lat, rail[b].lng);
      if (d <= km) out.add((a, b, const RouterConfig().walkMinutes(d) + 2));
    }
  }
  return out;
}

class _Point {
  const _Point(this.key, this.name, this.lat, this.lng, {this.isStation = false});

  final String key;
  final String name;
  final double lat;
  final double lng;
  final bool isStation;
}

/// Titik ujung akses: semua stasiun rel dan halte BRT, digabung kalau
/// berjarak kurang dari 200 m supaya tidak dobel per peron.
List<TransitStop> _anchors(List<TransitStop> stops, List<TransitPattern> patterns, int railCount) {
  final ids = <int>{for (var i = 0; i < railCount; i++) i};
  for (final p in patterns) {
    if (p.line.mode == RideMode.brt) ids.addAll(p.stops);
  }
  final out = <TransitStop>[];
  for (final i in ids.toList()..sort()) {
    final s = stops[i];
    if (out.any((a) => haversineKm(a.lat, a.lng, s.lat, s.lng) < 0.2)) continue;
    out.add(s);
  }
  return out;
}

List<_Point> _points(String city) {
  final out = <_Point>[];
  final st = parseCsv(File('supabase/seed/station.csv').readAsStringSync());
  for (final r in st.rows) {
    if (st.cell(r, 'city') != city) continue;
    final lat = double.tryParse(st.cell(r, 'lat'));
    final lng = double.tryParse(st.cell(r, 'lng'));
    if (lat == null || lng == null) continue;
    out.add(_Point(st.cell(r, 'code'), st.cell(r, 'name'), lat, lng, isStation: true));
  }
  final pl = parseCsv(File('supabase/seed/place.csv').readAsStringSync());
  for (final r in pl.rows) {
    if (pl.cell(r, 'city') != city) continue;
    out.add(_Point(pl.cell(r, 'key'), pl.cell(r, 'name'), double.parse(pl.cell(r, 'lat')), double.parse(pl.cell(r, 'lng'))));
  }
  return out;
}
