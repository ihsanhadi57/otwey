import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../domain/access_route.dart';
import '../domain/access_route_repository.dart';
import 'seed_access_route_repository.dart';

final accessRouteRepositoryProvider = Provider<AccessRouteRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseAccessRouteRepository(ref.watch(supabaseClientProvider));
  }
  return SeedAccessRouteRepository();
});

class SupabaseAccessRouteRepository implements AccessRouteRepository {
  SupabaseAccessRouteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AccessRoute>> fetchAll() async {
    final rows = await _client
        .from('mst_access_route')
        .select(
          'code, station_code, direction, name, anchor_lat, anchor_lng, '
          'mst_access_step(step_seq, mode, service, corridor, from_stop, '
          'to_stop, minutes, fare, operating_hours)',
        )
        .eq('is_active', true)
        .order('code');

    return [
      for (final r in rows)
        AccessRoute(
          code: r['code'] as String,
          stationCode: r['station_code'] as String,
          direction: AccessDirection.fromDb(r['direction'] as String),
          name: r['name'] as String,
          anchorLat: (r['anchor_lat'] as num?)?.toDouble(),
          anchorLng: (r['anchor_lng'] as num?)?.toDouble(),
          steps: [
            for (final s in (r['mst_access_step'] as List)
                .cast<Map<String, dynamic>>()
              ..sort((a, b) => (a['step_seq'] as int).compareTo(b['step_seq'] as int)))
              AccessStep(
                seq: s['step_seq'] as int,
                mode: s['mode'] as String,
                minutes: s['minutes'] as int,
                fare: s['fare'] as int,
                service: s['service'] as String?,
                corridor: s['corridor'] as String?,
                fromStop: s['from_stop'] as String?,
                toStop: s['to_stop'] as String?,
                operatingHours: s['operating_hours'] as String?,
              ),
          ],
        ),
    ];
  }
}