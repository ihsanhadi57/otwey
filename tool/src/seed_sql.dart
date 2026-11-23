/// Mengubah SeedData tervalidasi menjadi supabase/seed.sql idempoten.
/// Semua insert memakai on conflict kunci alami (index unik dari migrasi kedua).
library;

import 'package:otwey/core/utils/seed_validate.dart';

String _s(String? v) => v == null || v.isEmpty ? 'null' : "'${v.replaceAll("'", "''")}'";

String _clock(int minutes) =>
    "'${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}'";

String _point(double? lat, double? lng) =>
    lat == null || lng == null ? 'null' : 'st_setsrid(st_makepoint($lng, $lat), 4326)::geography';

String _days(List<int> days) => "'{${days.join(',')}}'::smallint[]";

String _placeId(PlaceRow p) =>
    "(select id from mst_place where source = ${_s(p.source)} and source_ref = ${_s(p.sourceRef)})";

String emitSeedSql(SeedData data) {
  final b = StringBuffer();
  b.writeln('-- Dihasilkan tool/seed_import.dart dari supabase/seed/*.csv. Jangan edit manual.');
  b.writeln('-- Idempoten: jalankan berulang kali aman (upsert kunci alami).');
  b.writeln('begin;');
  b.writeln();

  for (final s in data.stations) {
    b.writeln("insert into mst_station (code, name, city, type, location) values "
        "(${_s(s.code)}, ${_s(s.name)}, ${_s(s.city)}, ${_s(s.type)}, ${_point(s.lat, s.lng)}) "
        "on conflict (code) do update set name = excluded.name, city = excluded.city, "
        "type = excluded.type, location = coalesce(excluded.location, mst_station.location);");
  }
  b.writeln();

  final trips = <String, List<WhooshRow>>{};
  for (final w in data.whoosh) {
    trips.putIfAbsent('${w.trainNo}|${w.direction}|${w.validFrom}', () => []).add(w);
  }
  for (final g in trips.values) {
    final t = g.first;
    final tripId = "(select id from mst_whoosh_trip where train_no = ${_s(t.trainNo)} "
        "and direction = ${_s(t.direction)} and valid_from = ${_s(t.validFrom)})";
    b.writeln("insert into mst_whoosh_trip (train_no, direction, valid_from, valid_to, service_days) values "
        "(${_s(t.trainNo)}, ${_s(t.direction)}, ${_s(t.validFrom)}, ${_s(t.validTo)}, ${_days(t.serviceDays)}) "
        "on conflict (train_no, direction, valid_from) where train_no is not null "
        "do update set valid_to = excluded.valid_to, service_days = excluded.service_days, is_active = true;");
    for (final w in g) {
      b.writeln("insert into mst_whoosh_trip_stop (trip_id, station_id, stop_sequence, arrival_time, departure_time) "
          "values ($tripId, (select id from mst_station where code = ${_s(w.stationCode)}), "
          "${w.seq}, ${w.arrive == null ? 'null' : _clock(w.arrive!)}, ${w.depart == null ? 'null' : _clock(w.depart!)}) "
          "on conflict (trip_id, stop_sequence) do update set station_id = excluded.station_id, "
          "arrival_time = excluded.arrival_time, departure_time = excluded.departure_time;");
    }
  }
  b.writeln();

  final routes = <String, List<FeederRow>>{};
  for (final f in data.feeders) {
    routes.putIfAbsent(f.routeName, () => []).add(f);
  }
  for (final e in routes.entries) {
    final f = e.value.first;
    b.writeln("insert into mst_feeder_route (name, mode, origin_station_id, destination_station_id, duration_minutes, fare, free_for_whoosh) "
        "values (${_s(f.routeName)}, ${_s(f.mode)}, (select id from mst_station where code = ${_s(f.fromStation)}), "
        "(select id from mst_station where code = ${_s(f.toStation)}), ${f.arrive - f.depart}, ${f.fare}, ${f.freeForWhoosh}) "
        "on conflict (name) do update set mode = excluded.mode, origin_station_id = excluded.origin_station_id, "
        "destination_station_id = excluded.destination_station_id, duration_minutes = excluded.duration_minutes, "
        "fare = excluded.fare, free_for_whoosh = excluded.free_for_whoosh;");
    for (final s in e.value) {
      final connects = s.connectsTrainNo.isEmpty
          ? 'null'
          : "(select id from mst_whoosh_trip where train_no = ${_s(s.connectsTrainNo)} limit 1)";
      b.writeln("insert into mst_feeder_schedule (route_id, departure_time, arrival_time, connects_trip_id, service_days) "
          "values ((select id from mst_feeder_route where name = ${_s(s.routeName)}), "
          "${_clock(s.depart)}, ${_clock(s.arrive)}, $connects, ${_days(s.serviceDays)}) "
          "on conflict (route_id, departure_time) do update set arrival_time = excluded.arrival_time, "
          "connects_trip_id = excluded.connects_trip_id, service_days = excluded.service_days;");
    }
  }
  b.writeln();

  final access = <String, List<AccessStepRow>>{};
  for (final a in data.accessSteps) {
    access.putIfAbsent(a.routeKey, () => []).add(a);
  }
  for (final e in access.entries) {
    final a = e.value.first;
    b.writeln("insert into mst_access_route (code, station_code, direction, name, anchor_lat, anchor_lng, source) values "
        "(${_s(a.routeKey)}, ${_s(a.stationCode)}, ${_s(a.direction)}, "
        "${_s(a.routeName.isEmpty ? a.routeKey : a.routeName)}, ${a.anchorLat ?? 'null'}, ${a.anchorLng ?? 'null'}, ${_s(a.source)}) "
        "on conflict (code) do update set station_code = excluded.station_code, "
        "direction = excluded.direction, name = excluded.name, anchor_lat = excluded.anchor_lat, "
        "anchor_lng = excluded.anchor_lng, source = excluded.source;");
    for (final s in e.value) {
      b.writeln("insert into mst_access_step (route_code, step_seq, mode, service, corridor, from_stop, to_stop, minutes, fare, operating_hours, source) "
          "values (${_s(s.routeKey)}, ${s.seq}, ${_s(s.mode)}, ${_s(s.service)}, ${_s(s.corridor)}, "
          "${_s(s.fromStop)}, ${_s(s.toStop)}, ${s.minutes}, ${s.fare}, ${_s(s.operatingHours)}, ${_s(s.source)}) "
          "on conflict (route_code, step_seq) do update set mode = excluded.mode, service = excluded.service, "
          "corridor = excluded.corridor, from_stop = excluded.from_stop, to_stop = excluded.to_stop, "
          "minutes = excluded.minutes, fare = excluded.fare, operating_hours = excluded.operating_hours, "
          "source = excluded.source;");
    }
  }
  b.writeln();

  for (final f in data.fareRules) {
    b.writeln("insert into mst_fare_rule (code, mode, city, base_fare, per_km_fare, min_fare, source) values "
        "(${_s(f.code)}, ${_s(f.mode)}, ${_s(f.city)}, ${f.baseFare}, ${f.perKmFare}, ${f.minFare}, ${_s(f.source)}) "
        "on conflict (code) do update set mode = excluded.mode, city = excluded.city, "
        "base_fare = excluded.base_fare, per_km_fare = excluded.per_km_fare, min_fare = excluded.min_fare, "
        "source = excluded.source;");
  }
  b.writeln();

  for (final p in data.places) {
    b.writeln("insert into mst_place (name, city, area, address, location, description, price_range, visit_minutes, source, source_ref, is_verified, google_place_id) "
        "values (${_s(p.name)}, ${_s(p.city)}, ${_s(p.area)}, ${_s(p.address)}, ${_point(p.lat, p.lng)}, "
        "${_s(p.description)}, ${_s(p.priceRange)}, ${p.visitMinutes}, ${_s(p.source)}, ${_s(p.sourceRef)}, ${p.isVerified}, "
        "${_s(p.googlePlaceId)}) "
        "on conflict (source, source_ref) do update set name = excluded.name, city = excluded.city, "
        "area = excluded.area, address = excluded.address, location = excluded.location, "
        "description = excluded.description, price_range = excluded.price_range, "
        "visit_minutes = excluded.visit_minutes, is_verified = excluded.is_verified, "
        // Jangan hapus place_id yang sudah diisi place-lookup batch.
        "google_place_id = coalesce(excluded.google_place_id, mst_place.google_place_id);");
    for (var i = 0; i < p.categories.length; i++) {
      b.writeln("insert into mst_place_category (place_id, category_code, is_primary) values "
          "(${_placeId(p)}, ${_s(p.categories[i])}, ${i == 0}) "
          "on conflict (place_id, category_code) do update set is_primary = excluded.is_primary;");
    }
    for (final a in p.attributes) {
      b.writeln("insert into mst_place_attribute (place_id, attribute_code) values "
          "(${_placeId(p)}, ${_s(a)}) on conflict (place_id, attribute_code) do nothing;");
    }
  }
  b.writeln();

  final byKey = {for (final p in data.places) p.key: p};
  for (final h in data.openingHours) {
    final p = byKey[h.placeKey];
    if (p == null) continue;
    b.writeln("insert into mst_place_opening_hour (place_id, day_of_week, open_time, close_time) values "
        "(${_placeId(p)}, ${h.day}, ${_clock(h.open)}, ${_clock(h.close)}) "
        "on conflict (place_id, day_of_week, open_time) do update set close_time = excluded.close_time;");
  }

  b.writeln();
  b.writeln('commit;');
  return b.toString();
}