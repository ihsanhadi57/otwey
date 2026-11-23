import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/geo.dart';
import '../../trip_setup/domain/trip_direction.dart';
import '../domain/schedule.dart';
import '../domain/schedule_repository.dart';
import 'seed_schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseScheduleRepository(ref.watch(supabaseClientProvider));
  }
  return SeedScheduleRepository();
});

class SupabaseScheduleRepository implements ScheduleRepository {
  SupabaseScheduleRepository(this._client);

  final SupabaseClient _client;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int? _time(Object? value) =>
      value == null ? null : Clock.parseDbTime(value as String);

  @override
  Future<List<Station>> fetchStations() async {
    final rows = await _client
        .from('mst_station')
        .select('id, code, name, city, location')
        .eq('is_active', true)
        .order('id', ascending: true);

    return [
      for (final r in rows)
        Station(
          id: r['id'] as int,
          code: r['code'] as String,
          name: r['name'] as String,
          city: r['city'] as String,
          lat: parseGeoPoint(r['location'])?.lat,
          lng: parseGeoPoint(r['location'])?.lng,
        ),
    ];
  }

  @override
  Future<List<WhooshTrip>> fetchWhooshTrips(
    TripDirection direction,
    DateTime date,
  ) async {
    final d = _date(date);
    final rows = await _client
        .from('mst_whoosh_trip')
        .select(
          'id, train_no, direction, '
          'mst_whoosh_trip_stop(stop_sequence, arrival_time, departure_time, '
          'mst_station(code))',
        )
        .eq('direction', direction.dbValue)
        .eq('is_active', true)
        .contains('service_days', [date.weekday])
        .lte('valid_from', d)
        .or('valid_to.is.null,valid_to.gte.$d');

    return [
      for (final r in rows)
        WhooshTrip(
          id: r['id'] as int,
          trainNo: r['train_no'] as String?,
          direction: TripDirection.fromDb(r['direction'] as String),
          stops: [
            for (final s in (r['mst_whoosh_trip_stop'] as List)
                .cast<Map<String, dynamic>>())
              WhooshStop(
                stationCode:
                    (s['mst_station'] as Map<String, dynamic>)['code'] as String,
                sequence: s['stop_sequence'] as int,
                arrival: _time(s['arrival_time']),
                departure: _time(s['departure_time']),
              ),
          ]..sort((a, b) => a.sequence.compareTo(b.sequence)),
        ),
    ];
  }

  @override
  Future<List<FeederDeparture>> fetchFeeders(DateTime date) async {
    final rows = await _client
        .from('mst_feeder_schedule')
        .select(
          'id, departure_time, arrival_time, connects_trip_id, '
          'route:mst_feeder_route!inner(name, mode, fare, free_for_whoosh, '
          'origin:mst_station!origin_station_id(code), '
          'destination:mst_station!destination_station_id(code))',
        )
        .eq('is_active', true)
        .eq('route.is_active', true)
        .contains('service_days', [date.weekday])
        .order('departure_time', ascending: true);

    return [for (final r in rows) _feeder(r)];
  }

  static FeederDeparture _feeder(Map<String, dynamic> r) {
    final route = r['route'] as Map<String, dynamic>;
    return FeederDeparture(
      id: r['id'] as int,
      routeName: route['name'] as String,
      mode: route['mode'] as String,
      originStationCode:
          (route['origin'] as Map<String, dynamic>)['code'] as String,
      destinationStationCode:
          (route['destination'] as Map<String, dynamic>)['code'] as String,
      departure: _time(r['departure_time'])!,
      arrival: _time(r['arrival_time'])!,
      fare: route['fare'] as int,
      freeForWhoosh: route['free_for_whoosh'] as bool,
      connectsTripId: r['connects_trip_id'] as int?,
    );
  }
}
