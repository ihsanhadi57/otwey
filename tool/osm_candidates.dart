/// Kandidat tempat dari OpenStreetMap (Overpass API) per zona demo.
///
/// Jalankan: dart run tool/osm_candidates.dart
/// Hasil: supabase/seed/candidates/osm_candidates.csv (kolom sama dengan
/// place.csv ditambah opening_hours mentah dan jam hasil parse). File ini
/// bukan seed: pilih baris yang layak, lengkapi deskripsi, lalu salin ke
/// place.csv dan place_opening_hour.csv.
///
/// Data OSM berlisensi ODbL: wajib atribusi "© OpenStreetMap contributors".
/// Bukan scraping Google Maps (dilarang ketentuan Google Maps Platform).
library;

import 'dart:convert';
import 'dart:io';

import 'package:otwey/core/utils/seed_csv.dart';

import 'src/osm_hours.dart';

/// Server Overpass publik. Dicoba bergantian dengan jeda bertambah kalau penuh.
const _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

/// Zona demo (docs/DATA_PLAN.md). bbox: selatan, barat, utara, timur.
const _zones = [
  (city: 'Bandung', area: 'Braga - Asia Afrika', bbox: (-6.9300, 107.5980, -6.9100, 107.6160)),
  (city: 'Bandung', area: 'Dago', bbox: (-6.9000, 107.6050, -6.8800, 107.6250)),
  (city: 'Jakarta', area: 'Kota Tua', bbox: (-6.1420, 106.8070, -6.1300, 106.8180)),
  (city: 'Jakarta', area: 'Blok M', bbox: (-6.2500, 106.7950, -6.2350, 106.8120)),
  (city: 'Jakarta', area: 'Thamrin - Sarinah', bbox: (-6.1950, 106.8180, -6.1800, 106.8260)),
  (city: 'Jakarta', area: 'Menteng - Cikini', bbox: (-6.2000, 106.8300, -6.1850, 106.8450)),
  (city: 'Jakarta', area: 'Gambir - Pasar Baru', bbox: (-6.1750, 106.8200, -6.1630, 106.8350)),
  (city: 'Jakarta', area: 'Senayan - SCBD', bbox: (-6.2300, 106.7980, -6.2150, 106.8180)),
  (city: 'Jakarta', area: 'Kemang', bbox: (-6.2760, 106.8120, -6.2600, 106.8250)),
];

const _header = [
  'key', 'name', 'city', 'area', 'address', 'lat', 'lng', 'description', 'price_range',
  'visit_minutes', 'categories', 'attributes', 'source', 'source_ref', 'is_verified',
  'osm_opening_hours', 'parsed_hours', 'osm_cuisine', 'osm_website',
];

/// Durasi kunjung default per kategori utama (menit). Saran, bukan data OSM.
const _visit = {
  'makanan_berat': 60, 'makanan_barat': 60, 'jajanan': 30, 'kopi_kafe': 45,
  'manis': 30, 'oleh_oleh': 30, 'sejarah_budaya': 60, 'seni_kreatif': 60,
  'alam': 45, 'belanja': 60, 'religi': 30, 'keluarga': 60,
};

Future<void> main(List<String> args) async {
  // `--kota=Jakarta`: hanya zona kota itu, hasil ke berkas terpisah.
  final only = args.where((a) => a.startsWith('--kota=')).map((a) => a.substring(7)).firstOrNull;
  final zones = only == null ? _zones : _zones.where((z) => z.city == only).toList();
  final existing = _existingRefs();
  final rows = <List<String>>[];
  final keys = <String>{...existing.keys};
  for (final z in zones) {
    stdout.writeln('Overpass: ${z.city} / ${z.area} ...');
    final elements = await _query(z.bbox);
    var added = 0;
    for (final e in elements) {
      final row = _toRow(e, z.city, z.area, keys, existing.refs);
      if (row == null) continue;
      rows.add(row);
      added++;
    }
    stdout.writeln('  $added kandidat');
    // Jeda antar request, sesuai etika pemakaian Overpass publik.
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  final out = File('supabase/seed/candidates/osm_candidates${only == null ? '' : '_${only.toLowerCase()}'}.csv');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(_csv([_header, ...rows]));
  final withHours = rows.where((r) => r[16].isNotEmpty).length;
  stdout.writeln('${rows.length} kandidat ditulis ke ${out.path} ($withHours dengan jam buka terbaca).');
}

({Set<String> keys, Set<String> refs}) _existingRefs() {
  final f = File('supabase/seed/place.csv');
  if (!f.existsSync()) return (keys: <String>{}, refs: <String>{});
  final t = parseCsv(f.readAsStringSync());
  return (
    keys: {for (final r in t.rows) t.cell(r, 'key')},
    refs: {for (final r in t.rows) t.cell(r, 'source_ref')},
  );
}

Future<List<Map<String, dynamic>>> _query((double, double, double, double) bbox) async {
  final b = '${bbox.$1},${bbox.$2},${bbox.$3},${bbox.$4}';
  final q = '''
[out:json][timeout:60];
(
  nwr["name"]["amenity"~"^(restaurant|cafe|fast_food|ice_cream|food_court|arts_centre)\$"]($b);
  nwr["name"]["shop"~"^(bakery|pastry|confectionery|gift|mall)\$"]($b);
  nwr["name"]["tourism"~"^(museum|gallery|attraction|viewpoint)\$"]($b);
  nwr["name"]["historic"]($b);
  nwr["name"]["leisure"~"^(park|garden)\$"]($b);
);
out center tags;
''';
  Object? lastError;
  for (var attempt = 0; attempt < 6; attempt++) {
    final endpoint = _endpoints[attempt % _endpoints.length];
    try {
      return await _post(endpoint, q);
    } on Exception catch (e) {
      lastError = e;
      final wait = Duration(seconds: 5 * (1 << (attempt ~/ _endpoints.length)));
      final reason = e.toString().split('\n').first;
      stderr.writeln('  gagal di $endpoint ($reason), coba lagi ${wait.inSeconds} dtk');
      await Future<void>.delayed(wait);
    }
  }
  throw Exception('Semua server Overpass gagal: $lastError');
}

Future<List<Map<String, dynamic>>> _post(String endpoint, String q) async {
  final client = HttpClient()
    ..userAgent = 'otwey-seed-tool/0.1'
    ..connectionTimeout = const Duration(seconds: 20);
  try {
    final req = await client.postUrl(Uri.parse(endpoint));
    req.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
    req.write('data=${Uri.encodeQueryComponent(q)}');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('Overpass ${res.statusCode}: ${body.substring(0, body.length.clamp(0, 200))}');
    }
    return (jsonDecode(body)['elements'] as List).cast<Map<String, dynamic>>();
  } finally {
    client.close();
  }
}

List<String>? _toRow(
  Map<String, dynamic> e,
  String city,
  String area,
  Set<String> keys,
  Set<String> existingRefs,
) {
  final tags = (e['tags'] as Map).cast<String, String>();
  final name = tags['name']?.trim() ?? '';
  final ref = '${e['type']}/${e['id']}';
  if (name.isEmpty || existingRefs.contains(ref)) return null;
  final lat = (e['lat'] ?? e['center']?['lat']) as num?;
  final lng = (e['lon'] ?? e['center']?['lon']) as num?;
  if (lat == null || lng == null) return null;
  final categories = _categories(tags);
  if (categories.isEmpty) return null;

  var key = _slug(name);
  if (key.isEmpty) return null;
  if (!keys.add(key)) {
    key = '${key}_${e['id']}';
    if (!keys.add(key)) return null;
  }
  final street = tags['addr:street'];
  final number = tags['addr:housenumber'];
  final address = [?street, if (number != null) 'No. $number'].join(' ');
  final rawHours = tags['opening_hours'] ?? '';
  final hours = parseOsmOpeningHours(rawHours);
  return [
    key, name, city, area, address, lat.toStringAsFixed(7), lng.toStringAsFixed(7),
    '', '', '${_visit[categories.first] ?? 45}', categories.join(';'), _attributes(tags).join(';'),
    'osm', ref, 'false',
    rawHours,
    hours == null ? '' : hours.map((h) => '${h.day}@${_hhmm(h.open)}-${_hhmm(h.close)}').join(' '),
    tags['cuisine'] ?? '',
    tags['website'] ?? tags['contact:website'] ?? tags['contact:instagram'] ?? '',
  ];
}

/// Kategori master dari tag OSM. Kategori pertama = utama. Konservatif:
/// tag yang ambigu tidak dipetakan.
List<String> _categories(Map<String, String> t) {
  final amenity = t['amenity'];
  final shop = t['shop'];
  final tourism = t['tourism'];
  final cuisine = (t['cuisine'] ?? '').toLowerCase();
  final western = RegExp(r'pizza|burger|italian|steak|western|american|french|pasta').hasMatch(cuisine);
  final out = <String>[];
  void add(String c) {
    if (!out.contains(c)) out.add(c);
  }

  switch (amenity) {
    case 'restaurant' || 'food_court':
      add(western ? 'makanan_barat' : 'makanan_berat');
    case 'fast_food':
      add(western ? 'makanan_barat' : 'jajanan');
    case 'cafe':
      add('kopi_kafe');
    case 'ice_cream':
      add('manis');
    case 'arts_centre':
      add('seni_kreatif');
  }
  switch (shop) {
    case 'bakery' || 'pastry' || 'confectionery':
      add('manis');
      add('oleh_oleh');
    case 'gift':
      add('oleh_oleh');
    case 'mall':
      add('belanja');
  }
  switch (tourism) {
    case 'museum':
      add('sejarah_budaya');
    case 'gallery':
      add('seni_kreatif');
  }
  if (t['historic'] != null && t['historic'] != 'no') add('sejarah_budaya');
  if (t['leisure'] == 'park' || t['leisure'] == 'garden') add('alam');
  if (RegExp(r'dessert|cake|donut|ice_cream').hasMatch(cuisine)) add('manis');
  if (RegExp(r'coffee').hasMatch(cuisine)) add('kopi_kafe');
  return out;
}

List<String> _attributes(Map<String, String> t) => [
      if (t['diet:halal'] == 'yes' || t['diet:halal'] == 'only') 'halal',
      if (t['tourism'] == 'museum' || t['shop'] == 'mall') 'indoor',
      if (t['leisure'] == 'park' || t['leisure'] == 'garden') 'outdoor',
    ];

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\(.*?\)'), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

String _csv(List<List<String>> rows) => rows
    .map((r) => r.map((c) => RegExp(r'[",\n]').hasMatch(c) ? '"${c.replaceAll('"', '""')}"' : c).join(','))
    .join('\n');
