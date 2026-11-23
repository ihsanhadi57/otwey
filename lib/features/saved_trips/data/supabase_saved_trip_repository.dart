import 'package:supabase_flutter/supabase_flutter.dart';

import '../../planner/data/itinerary_codec.dart';
import '../../planner/domain/itinerary.dart';
import '../../planner/domain/leg_mode.dart';
import '../../trip_setup/domain/trip_direction.dart';
import '../domain/saved_trip.dart';
import '../domain/saved_trip_repository.dart';

/// Trip tersimpan di `trx_plan`, terikat user anonim/login lewat RLS owner.
/// Satu trip aktif: baris terakhir berstatus `saved` milik user.
class SupabaseSavedTripRepository implements SavedTripRepository {
  SupabaseSavedTripRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Trip tersimpan butuh sesi anonim.');
    return uid;
  }

  @override
  Future<SavedTrip?> fetch() async {
    final rows = await _client
        .from('trx_plan')
        .select('id, itinerary_json, choices_json')
        .eq('user_id', _userId)
        .eq('status', 'saved')
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final itJson = r['itinerary_json'];
    if (itJson == null) return null;
    return SavedTrip(
      id: r['id'] as String,
      itinerary: itineraryFromJson(Map<String, dynamic>.from(itJson as Map)),
      choices: legChoicesFromJson(Map<String, dynamic>.from(r['choices_json'] as Map? ?? {})),
    );
  }

  @override
  Future<String> save(SavedTrip trip) async {
    final it = trip.itinerary;
    final payload = {
      'user_id': _userId,
      'direction': _direction(it),
      'origin_label': it.originLabel,
      'travel_date': _date(it.date),
      'earliest_departure': _time(it.startTime),
      'latest_return': _time(it.latestReturn),
      'status': 'saved',
      'itinerary_json': itineraryToJson(it),
      'choices_json': legChoicesToJson(trip.choices),
    };
    final id = trip.id;
    if (id != null && id != 'local') {
      await _client.from('trx_plan').update(payload).eq('id', id).eq('user_id', _userId);
      return id;
    }
    final row = await _client.from('trx_plan').insert(payload).select('id').single();
    return row['id'] as String;
  }

  @override
  Future<void> updateChoices(String id, Map<String, LegMode> choices) async {
    await _client
        .from('trx_plan')
        .update({'choices_json': legChoicesToJson(choices)})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> clear() async {
    await _client.from('trx_plan').delete().eq('user_id', _userId).eq('status', 'saved');
  }

  static String _direction(Itinerary it) => TripDirection.values
      .firstWhere((d) => d.originCity == it.originCity && d.destinationCity == it.destinationCity)
      .dbValue;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _time(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }
}