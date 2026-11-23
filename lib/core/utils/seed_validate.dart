/// Validasi baris seed CSV dan hasil parse bertipe. Dipakai importer (tool/)
/// dan repository mode seed, supaya aturan tolaknya satu sumber.
library;

import 'seed_csv.dart';
import 'seed_rules.dart';

class SeedIssue {
  const SeedIssue(this.file, this.line, this.message);

  final String file;
  final int line;
  final String message;

  @override
  String toString() => '$file:$line: $message';
}

/// Dilempar repository mode seed kalau CSV belum layak pakai.
class SeedDataException implements Exception {
  const SeedDataException(this.issues);

  final List<SeedIssue> issues;

  @override
  String toString() =>
      'Data seed belum siap (${issues.length} masalah):\n${issues.join('\n')}';
}

class StationRow {
  const StationRow(this.code, this.name, this.city, this.type, this.lat, this.lng, this.source);

  final String code;
  final String name;
  final String city;
  final String type;
  final double? lat;
  final double? lng;
  final String source;
}

class WhooshRow {
  const WhooshRow({
    required this.trainNo,
    required this.direction,
    required this.stationCode,
    required this.seq,
    required this.arrive,
    required this.depart,
    required this.validFrom,
    required this.validTo,
    required this.source,
    this.serviceDays = allDays,
  });

  final String trainNo;
  final String direction;
  final String stationCode;
  final int seq;
  final int? arrive;
  final int? depart;
  final String validFrom;
  final String validTo;
  final String source;

  /// Hari operasi ISO (1 Senin sampai 7 Minggu). Kolom kosong = tiap hari.
  final List<int> serviceDays;
}

class FeederRow {
  const FeederRow({
    required this.routeName,
    required this.mode,
    required this.fromStation,
    required this.toStation,
    required this.depart,
    required this.arrive,
    required this.fare,
    required this.freeForWhoosh,
    required this.connectsTrainNo,
    required this.source,
    this.serviceDays = allDays,
  });

  final String routeName;
  final String mode;
  final String fromStation;
  final String toStation;
  final int depart;
  final int arrive;
  final int fare;
  final bool freeForWhoosh;
  final String connectsTrainNo;
  final String source;

  /// Hari operasi ISO. Kolom kosong = tiap hari.
  final List<int> serviceDays;
}

class AccessStepRow {
  const AccessStepRow({
    required this.routeKey,
    required this.stationCode,
    required this.direction,
    required this.seq,
    required this.mode,
    required this.service,
    required this.corridor,
    required this.fromStop,
    required this.toStop,
    required this.minutes,
    required this.fare,
    required this.operatingHours,
    required this.source,
    this.routeName = '',
    this.anchorLat,
    this.anchorLng,
  });

  final String routeKey;
  final String routeName;

  /// Titik ujung rute di sisi kota (halte atau stasiun pertama/terakhir),
  /// supaya planner bisa menghitung jalan atau ojol dari asal user ke sana.
  final double? anchorLat;
  final double? anchorLng;
  final String stationCode;
  final String direction;
  final int seq;
  final String mode;
  final String service;
  final String corridor;
  final String fromStop;
  final String toStop;
  final int minutes;
  final int fare;
  final String operatingHours;
  final String source;
}

class FareRuleRow {
  const FareRuleRow({
    required this.code,
    required this.mode,
    required this.city,
    required this.baseFare,
    required this.perKmFare,
    required this.minFare,
    required this.source,
  });

  final String code;
  final String mode;
  final String city;
  final int baseFare;
  final int perKmFare;
  final int minFare;
  final String source;
}

class PlaceRow {
  const PlaceRow({
    required this.key,
    required this.name,
    required this.city,
    required this.area,
    required this.address,
    required this.lat,
    required this.lng,
    required this.description,
    required this.priceRange,
    required this.visitMinutes,
    required this.categories,
    required this.attributes,
    required this.source,
    required this.sourceRef,
    required this.isVerified,
    this.googlePlaceId = '',
  });

  final String key;
  final String name;
  final String city;
  final String area;
  final String address;
  final double lat;
  final double lng;
  final String description;
  final String priceRange;
  final int visitMinutes;
  final List<String> categories;
  final List<String> attributes;
  final String source;
  final String sourceRef;
  final bool isVerified;

  /// Kolom opsional `google_place_id`. Kosong kalau belum ada.
  final String googlePlaceId;
}

class OpeningHourRow {
  const OpeningHourRow(this.placeKey, this.day, this.open, this.close);

  final String placeKey;
  final int day;
  final int open;
  final int close;
}

class SeedData {
  const SeedData({
    this.stations = const [],
    this.whoosh = const [],
    this.feeders = const [],
    this.accessSteps = const [],
    this.fareRules = const [],
    this.places = const [],
    this.openingHours = const [],
    this.issues = const [],
    this.warnings = const [],
  });

  final List<StationRow> stations;
  final List<WhooshRow> whoosh;
  final List<FeederRow> feeders;
  final List<AccessStepRow> accessSteps;
  final List<FareRuleRow> fareRules;
  final List<PlaceRow> places;
  final List<OpeningHourRow> openingHours;
  final List<SeedIssue> issues;
  final List<SeedIssue> warnings;

  bool get ok => issues.isEmpty;
}

/// Nama file yang dikenali importer. File lain di supabase/seed diabaikan.
const seedFileNames = [
  'station', 'whoosh_trip', 'feeder_schedule', 'access_route',
  'fare_rule', 'place', 'place_opening_hour',
];

/// Semua hari ISO, nilai default kolom `service_days` yang kosong.
const allDays = [1, 2, 3, 4, 5, 6, 7];

SeedData validateSeed(Map<String, String> files) {
  final issues = <SeedIssue>[];
  final warnings = <SeedIssue>[];
  final stations = <StationRow>[];
  final whoosh = <WhooshRow>[];
  final feeders = <FeederRow>[];
  final accessSteps = <AccessStepRow>[];
  final fareRules = <FareRuleRow>[];
  final places = <PlaceRow>[];
  final hours = <OpeningHourRow>[];

  CsvTable? table(String name) {
    final content = files[name];
    if (content == null) return null;
    final t = parseCsv(content);
    if (t.rows.isEmpty) {
      issues.add(SeedIssue('$name.csv', 1, 'file kosong atau hanya header, belum ada data'));
      return null;
    }
    return t;
  }

  void requireCell(String file, CsvRow row, String value, String column) {
    if (value.isEmpty) {
      issues.add(SeedIssue(file, row.line, 'kolom $column kosong'));
    } else if (hasPlaceholder(value)) {
      issues.add(SeedIssue(file, row.line, 'kolom $column masih template "$value", isi dulu'));
    }
  }

  int? intCell(String file, CsvRow row, String value, String column, {int min = 0}) {
    requireCell(file, row, value, column);
    final v = int.tryParse(value);
    if (value.isEmpty || hasPlaceholder(value)) return null;
    if (v == null || v < min) {
      issues.add(SeedIssue(file, row.line, 'kolom $column harus angka >= $min, dapat "$value"'));
      return null;
    }
    return v;
  }

  double? coordCell(String file, CsvRow row, String value, String column) {
    final v = double.tryParse(value);
    if (v == null) {
      issues.add(SeedIssue(file, row.line, 'kolom $column bukan koordinat valid: "$value"'));
      return null;
    }
    return v;
  }

  /// `service_days` berformat '1;2;3', kosong berarti tiap hari.
  List<int>? daysCell(String file, CsvRow row, String value) {
    if (value.isEmpty) return allDays;
    final days = <int>[];
    for (final c in splitCodes(value)) {
      final d = int.tryParse(c);
      if (d == null || d < 1 || d > 7) {
        issues.add(SeedIssue(file, row.line, 'service_days harus angka 1 sampai 7 dipisah ;, dapat "$value"'));
        return null;
      }
      days.add(d);
    }
    return days;
  }

  void enumCell(String file, CsvRow row, String value, String column, Set<String> allowed) {
    requireCell(file, row, value, column);
    if (value.isNotEmpty && !hasPlaceholder(value) && !allowed.contains(value)) {
      issues.add(SeedIssue(file, row.line, 'kolom $column "$value" tidak dikenal, pilih: ${allowed.join(', ')}'));
    }
  }

  // Stasiun: koordinat boleh kosong dulu (TODO(hadi)), tapi kalau ada harus dalam kota.
  final st = table('station');
  if (st != null) {
    for (final row in st.rows) {
      final code = st.cell(row, 'code');
      final name = st.cell(row, 'name');
      final city = st.cell(row, 'city');
      final type = st.cell(row, 'type');
      final source = st.cell(row, 'source');
      final latS = st.cell(row, 'lat');
      final lngS = st.cell(row, 'lng');
      requireCell('station.csv', row, code, 'code');
      requireCell('station.csv', row, name, 'name');
      requireCell('station.csv', row, city, 'city');
      enumCell('station.csv', row, type, 'type', {'whoosh', 'feeder', 'hub'});
      requireCell('station.csv', row, source, 'source');
      if (!masterStations.contains(code) && code.isNotEmpty && !hasPlaceholder(code)) {
        issues.add(SeedIssue('station.csv', row.line, 'kode stasiun $code belum ada di master init'));
      }
      double? lat;
      double? lng;
      if (latS.isEmpty || lngS.isEmpty) {
        warnings.add(SeedIssue('station.csv', row.line, 'TODO(hadi): koordinat $code kosong, planner belum bisa hitung jarak'));
      } else {
        lat = coordCell('station.csv', row, latS, 'lat');
        lng = coordCell('station.csv', row, lngS, 'lng');
        final bounds = cityBounds[city];
        if (lat != null && lng != null && bounds != null && !bounds.contains(lat, lng)) {
          issues.add(SeedIssue('station.csv', row.line, 'koordinat $code di luar kota $city'));
        }
      }
      stations.add(StationRow(code, name, city, type, lat, lng, source));
    }
  }

  final wt = table('whoosh_trip');
  if (wt != null) {
    for (final row in wt.rows) {
      final trainNo = wt.cell(row, 'train_no');
      final direction = wt.cell(row, 'direction');
      final station = wt.cell(row, 'station_code');
      final seqS = wt.cell(row, 'stop_seq');
      final arriveS = wt.cell(row, 'arrive');
      final departS = wt.cell(row, 'depart');
      final validFrom = wt.cell(row, 'valid_from');
      final source = wt.cell(row, 'source');
      requireCell('whoosh_trip.csv', row, trainNo, 'train_no');
      enumCell('whoosh_trip.csv', row, direction, 'direction', tripDirections);
      enumCell('whoosh_trip.csv', row, station, 'station_code', masterStations);
      requireCell('whoosh_trip.csv', row, validFrom, 'valid_from');
      requireCell('whoosh_trip.csv', row, source, 'source');
      final seq = intCell('whoosh_trip.csv', row, seqS, 'stop_seq', min: 1);
      if (DateTime.tryParse(validFrom) == null && validFrom.isNotEmpty && !hasPlaceholder(validFrom)) {
        issues.add(SeedIssue('whoosh_trip.csv', row.line, 'valid_from bukan tanggal YYYY-MM-DD: "$validFrom"'));
      }
      int? arrive;
      int? depart;
      if (arriveS.isNotEmpty) {
        arrive = parseClock(arriveS);
        if (arrive == null) issues.add(SeedIssue('whoosh_trip.csv', row.line, 'arrive bukan jam HH:MM: "$arriveS"'));
      }
      if (departS.isNotEmpty) {
        depart = parseClock(departS);
        if (depart == null) issues.add(SeedIssue('whoosh_trip.csv', row.line, 'depart bukan jam HH:MM: "$departS"'));
      }
      if (arrive != null && depart != null && depart < arrive) {
        issues.add(SeedIssue('whoosh_trip.csv', row.line, 'depart lebih awal dari arrive di stop yang sama'));
      }
      final serviceDays = daysCell('whoosh_trip.csv', row, wt.cell(row, 'service_days'));
      if (seq == null || serviceDays == null) continue;
      whoosh.add(WhooshRow(
        trainNo: trainNo, direction: direction, stationCode: station, seq: seq,
        arrive: arrive, depart: depart, validFrom: validFrom,
        validTo: wt.cell(row, 'valid_to'), source: source, serviceDays: serviceDays,
      ));
    }
    // Urutan stop per kereta: 1..n berurutan, awal tanpa arrive, akhir tanpa depart.
    final groups = <String, List<WhooshRow>>{};
    for (final r in whoosh) {
      groups.putIfAbsent('${r.trainNo}|${r.direction}|${r.validFrom}', () => []).add(r);
    }
    for (final g in groups.values) {
      g.sort((a, b) => a.seq.compareTo(b.seq));
      for (var i = 0; i < g.length; i++) {
        if (g[i].seq != i + 1) {
          issues.add(SeedIssue('whoosh_trip.csv', 0, 'stop_seq ${g[i].trainNo} tidak berurutan dari 1'));
          break;
        }
      }
      if (g.first.arrive != null) {
        issues.add(SeedIssue('whoosh_trip.csv', 0, 'stop awal ${g.first.trainNo} tidak boleh punya arrive'));
      }
      if (g.last.depart != null) {
        issues.add(SeedIssue('whoosh_trip.csv', 0, 'stop akhir ${g.last.trainNo} tidak boleh punya depart'));
      }
      for (var i = 1; i < g.length; i++) {
        final prev = g[i - 1].depart;
        final cur = g[i].arrive;
        if (prev != null && cur != null && cur < prev) {
          issues.add(SeedIssue('whoosh_trip.csv', 0, 'jam ${g[i].trainNo} mundur antara stop ${g[i - 1].seq} dan ${g[i].seq}'));
        }
      }
    }
  }

  final ft = table('feeder_schedule');
  if (ft != null) {
    final trainNos = whoosh.map((w) => w.trainNo).toSet();
    for (final row in ft.rows) {
      final routeName = ft.cell(row, 'route_name');
      final mode = ft.cell(row, 'mode');
      final from = ft.cell(row, 'from_station');
      final to = ft.cell(row, 'to_station');
      final departS = ft.cell(row, 'depart');
      final arriveS = ft.cell(row, 'arrive');
      final fareS = ft.cell(row, 'fare');
      final freeS = ft.cell(row, 'free_for_whoosh');
      final connects = ft.cell(row, 'connects_train_no');
      final source = ft.cell(row, 'source');
      requireCell('feeder_schedule.csv', row, routeName, 'route_name');
      enumCell('feeder_schedule.csv', row, mode, 'mode', transportModes);
      enumCell('feeder_schedule.csv', row, from, 'from_station', masterStations);
      enumCell('feeder_schedule.csv', row, to, 'to_station', masterStations);
      requireCell('feeder_schedule.csv', row, source, 'source');
      final depart = parseClock(departS);
      final arrive = parseClock(arriveS);
      if (depart == null) issues.add(SeedIssue('feeder_schedule.csv', row.line, 'depart bukan jam HH:MM: "$departS"'));
      if (arrive == null) issues.add(SeedIssue('feeder_schedule.csv', row.line, 'arrive bukan jam HH:MM: "$arriveS"'));
      if (depart != null && arrive != null && arrive <= depart) {
        issues.add(SeedIssue('feeder_schedule.csv', row.line, 'arrive harus setelah depart'));
      }
      final fare = intCell('feeder_schedule.csv', row, fareS, 'fare');
      if (freeS != 'true' && freeS != 'false') {
        issues.add(SeedIssue('feeder_schedule.csv', row.line, 'free_for_whoosh harus true/false, dapat "$freeS"'));
      }
      if (connects.isNotEmpty && !hasPlaceholder(connects) && !trainNos.contains(connects)) {
        issues.add(SeedIssue('feeder_schedule.csv', row.line, 'connects_train_no $connects tidak ada di whoosh_trip.csv'));
      }
      final serviceDays = daysCell('feeder_schedule.csv', row, ft.cell(row, 'service_days'));
      if (depart == null || arrive == null || fare == null || serviceDays == null) continue;
      feeders.add(FeederRow(
        routeName: routeName, mode: mode, fromStation: from, toStation: to,
        depart: depart, arrive: arrive, fare: fare, freeForWhoosh: freeS == 'true',
        connectsTrainNo: connects, source: source, serviceDays: serviceDays,
      ));
    }
  }

  final at = table('access_route');
  if (at != null) {
    for (final row in at.rows) {
      final routeKey = at.cell(row, 'route_key');
      final station = at.cell(row, 'station_code');
      final direction = at.cell(row, 'direction');
      final seqS = at.cell(row, 'step_seq');
      final mode = at.cell(row, 'mode');
      final minutesS = at.cell(row, 'minutes');
      final fareS = at.cell(row, 'fare');
      final source = at.cell(row, 'source');
      requireCell('access_route.csv', row, routeKey, 'route_key');
      enumCell('access_route.csv', row, station, 'station_code', masterStations);
      enumCell('access_route.csv', row, direction, 'direction', accessDirections);
      enumCell('access_route.csv', row, mode, 'mode', transportModes);
      requireCell('access_route.csv', row, source, 'source');
      final seq = intCell('access_route.csv', row, seqS, 'step_seq', min: 1);
      final minutes = intCell('access_route.csv', row, minutesS, 'minutes', min: 1);
      final fare = intCell('access_route.csv', row, fareS, 'fare');
      if (seq == null || minutes == null || fare == null) continue;
      accessSteps.add(AccessStepRow(
        routeKey: routeKey, stationCode: station, direction: direction, seq: seq,
        mode: mode, service: at.cell(row, 'service'), corridor: at.cell(row, 'corridor'),
        fromStop: at.cell(row, 'from_stop'), toStop: at.cell(row, 'to_stop'),
        minutes: minutes, fare: fare, operatingHours: at.cell(row, 'operating_hours'),
        source: source, routeName: at.cell(row, 'route_name'),
        anchorLat: double.tryParse(at.cell(row, 'anchor_lat')),
        anchorLng: double.tryParse(at.cell(row, 'anchor_lng')),
      ));
    }
    final groups = <String, List<AccessStepRow>>{};
    for (final r in accessSteps) {
      groups.putIfAbsent(r.routeKey, () => []).add(r);
    }
    for (final e in groups.entries) {
      final g = e.value..sort((a, b) => a.seq.compareTo(b.seq));
      for (var i = 0; i < g.length; i++) {
        if (g[i].seq != i + 1) {
          issues.add(SeedIssue('access_route.csv', 0, 'step_seq rute ${e.key} tidak berurutan dari 1'));
          break;
        }
      }
    }
  }

  final fr = table('fare_rule');
  if (fr != null) {
    for (final row in fr.rows) {
      final code = fr.cell(row, 'code');
      final mode = fr.cell(row, 'mode');
      final baseS = fr.cell(row, 'base_fare');
      final perKmS = fr.cell(row, 'per_km_fare');
      final minS = fr.cell(row, 'min_fare');
      final source = fr.cell(row, 'source');
      requireCell('fare_rule.csv', row, code, 'code');
      enumCell('fare_rule.csv', row, mode, 'mode', {'two_wheeler', 'drive'});
      requireCell('fare_rule.csv', row, source, 'source');
      final base = intCell('fare_rule.csv', row, baseS, 'base_fare');
      final perKm = intCell('fare_rule.csv', row, perKmS, 'per_km_fare');
      final minFare = minS.isEmpty ? 0 : intCell('fare_rule.csv', row, minS, 'min_fare');
      if (base == null || perKm == null || minFare == null) continue;
      fareRules.add(FareRuleRow(
        code: code, mode: mode, city: fr.cell(row, 'city'),
        baseFare: base, perKmFare: perKm, minFare: minFare, source: source,
      ));
    }
  }

  final pt = table('place');
  if (pt != null) {
    final seen = <String>{};
    for (final row in pt.rows) {
      final key = pt.cell(row, 'key');
      final name = pt.cell(row, 'name');
      final city = pt.cell(row, 'city');
      final latS = pt.cell(row, 'lat');
      final lngS = pt.cell(row, 'lng');
      final visitS = pt.cell(row, 'visit_minutes');
      final source = pt.cell(row, 'source');
      final sourceRef = pt.cell(row, 'source_ref');
      final verifiedS = pt.cell(row, 'is_verified');
      requireCell('place.csv', row, key, 'key');
      requireCell('place.csv', row, name, 'name');
      requireCell('place.csv', row, city, 'city');
      requireCell('place.csv', row, source, 'source');
      requireCell('place.csv', row, sourceRef, 'source_ref');
      enumCell('place.csv', row, source, 'source', dataSources);
      if (!seen.add(key) && key.isNotEmpty) {
        issues.add(SeedIssue('place.csv', row.line, 'key $key duplikat'));
      }
      final bounds = cityBounds[city];
      if (bounds == null && city.isNotEmpty && !hasPlaceholder(city)) {
        issues.add(SeedIssue('place.csv', row.line, 'kota $city di luar zona demo (Bandung/Jakarta)'));
      }
      final lat = coordCell('place.csv', row, latS, 'lat');
      final lng = coordCell('place.csv', row, lngS, 'lng');
      if (lat != null && lng != null && bounds != null && !bounds.contains(lat, lng)) {
        issues.add(SeedIssue('place.csv', row.line, 'koordinat $key di luar kota $city'));
      }
      final visit = intCell('place.csv', row, visitS, 'visit_minutes', min: 1);
      final price = pt.cell(row, 'price_range');
      if (price.isNotEmpty && !hasPlaceholder(price) && !priceRanges.contains(price)) {
        issues.add(SeedIssue('place.csv', row.line, 'price_range "$price" tidak dikenal'));
      }
      final categories = splitCodes(pt.cell(row, 'categories'));
      final attributes = splitCodes(pt.cell(row, 'attributes'));
      for (final c in categories) {
        if (!masterCategories.contains(c)) {
          issues.add(SeedIssue('place.csv', row.line, 'kategori $c tidak ada di mst_category'));
        }
      }
      for (final a in attributes) {
        if (!masterAttributes.contains(a)) {
          issues.add(SeedIssue('place.csv', row.line, 'atribut $a tidak ada di mst_attribute'));
        }
      }
      if (verifiedS != 'true' && verifiedS != 'false') {
        issues.add(SeedIssue('place.csv', row.line, 'is_verified harus true/false, dapat "$verifiedS"'));
      }
      if (lat == null || lng == null || visit == null) continue;
      places.add(PlaceRow(
        key: key, name: name, city: city, area: pt.cell(row, 'area'),
        address: pt.cell(row, 'address'), lat: lat, lng: lng,
        description: pt.cell(row, 'description'), priceRange: price,
        visitMinutes: visit, categories: categories, attributes: attributes,
        source: source, sourceRef: sourceRef, isVerified: verifiedS == 'true',
        googlePlaceId: pt.cell(row, 'google_place_id'),
      ));
    }
  }

  final ot = table('place_opening_hour');
  if (ot != null) {
    final placeKeys = places.map((p) => p.key).toSet();
    for (final row in ot.rows) {
      final placeKey = ot.cell(row, 'place_key');
      final dayS = ot.cell(row, 'day_of_week');
      final openS = ot.cell(row, 'open');
      final closeS = ot.cell(row, 'close');
      requireCell('place_opening_hour.csv', row, placeKey, 'place_key');
      if (!placeKeys.contains(placeKey) && placeKey.isNotEmpty && !hasPlaceholder(placeKey)) {
        issues.add(SeedIssue('place_opening_hour.csv', row.line, 'place_key $placeKey tidak ada di place.csv'));
      }
      final day = intCell('place_opening_hour.csv', row, dayS, 'day_of_week', min: 1);
      if (day != null && day > 7) {
        issues.add(SeedIssue('place_opening_hour.csv', row.line, 'day_of_week harus 1 sampai 7'));
      }
      final open = parseClock(openS);
      final close = parseClock(closeS);
      if (open == null) issues.add(SeedIssue('place_opening_hour.csv', row.line, 'open bukan jam HH:MM: "$openS"'));
      if (close == null) issues.add(SeedIssue('place_opening_hour.csv', row.line, 'close bukan jam HH:MM: "$closeS"'));
      if (open != null && close != null && close <= open) {
        issues.add(SeedIssue('place_opening_hour.csv', row.line, 'close harus setelah open'));
      }
      if (day == null || open == null || close == null || day > 7) continue;
      hours.add(OpeningHourRow(placeKey, day, open, close));
    }
  }

  return SeedData(
    stations: stations, whoosh: whoosh, feeders: feeders, accessSteps: accessSteps,
    fareRules: fareRules, places: places, openingHours: hours,
    issues: issues, warnings: warnings,
  );
}