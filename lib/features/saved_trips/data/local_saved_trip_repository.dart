import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../planner/data/itinerary_codec.dart';
import '../../planner/domain/leg_mode.dart';
import '../domain/saved_trip.dart';
import '../domain/saved_trip_repository.dart';

/// Trip tersimpan di perangkat saat Supabase/auth tidak tersedia (demo offline).
class LocalSavedTripRepository implements SavedTripRepository {
  static const _key = 'otwey_saved_trip';

  @override
  Future<SavedTrip?> fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SavedTrip(
      id: json['id'] as String?,
      itinerary: itineraryFromJson(json['itinerary'] as Map<String, dynamic>),
      choices: legChoicesFromJson(json['choices'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  Future<String> save(SavedTrip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final id = trip.id ?? 'local';
    await prefs.setString(
      _key,
      jsonEncode({
        'id': id,
        'itinerary': itineraryToJson(trip.itinerary),
        'choices': legChoicesToJson(trip.choices),
      }),
    );
    return id;
  }

  @override
  Future<void> updateChoices(String id, Map<String, LegMode> choices) async {
    final current = await fetch();
    if (current == null) return;
    await save(SavedTrip(id: id, itinerary: current.itinerary, choices: choices));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}