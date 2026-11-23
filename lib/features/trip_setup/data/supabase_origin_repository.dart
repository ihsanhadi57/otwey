import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/geo.dart';
import '../../planner/domain/schedule_repository.dart';
import '../domain/origin_point.dart';
import '../domain/origin_repository.dart';

/// Titik berangkat dari `trx_saved_origin` (milik user) plus stasiun di kota itu.
/// ETA ke stasiun belum ada datanya, dibiarkan null sampai ada waktu tempuh asli.
class SupabaseOriginRepository implements OriginRepository {
  SupabaseOriginRepository(this._client, this._schedules);

  final SupabaseClient _client;
  final ScheduleRepository _schedules;

  @override
  Future<List<OriginPoint>> fetchByCity(String city) async {
    final stations = await _schedules.fetchStations();
    final origins = <OriginPoint>[
      for (final s in stations)
        if (s.city == city)
          OriginPoint(
            id: 'station_${s.code}',
            label: s.name,
            address: s.city,
            kind: OriginKind.station,
            lat: s.lat,
            lng: s.lng,
          ),
    ];

    final uid = _client.auth.currentUser?.id;
    if (uid == null) return origins;

    final rows = await _client
        .from('trx_saved_origin')
        .select('id, label, address, kind, location')
        .eq('user_id', uid)
        .eq('city', city)
        .order('created_at');

    return [
      for (final r in rows)
        OriginPoint(
          id: r['id'] as String,
          label: r['label'] as String,
          address: r['address'] as String? ?? '',
          kind: _kind(r['kind'] as String?),
          lat: parseGeoPoint(r['location'])?.lat,
          lng: parseGeoPoint(r['location'])?.lng,
        ),
      ...origins,
    ];
  }

  static OriginKind _kind(String? value) => switch (value) {
        'home' => OriginKind.home,
        'work' => OriginKind.work,
        'station' => OriginKind.station,
        _ => OriginKind.other,
      };
}