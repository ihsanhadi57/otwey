import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/geo.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';

class SupabasePlaceRepository implements PlaceRepository {
  SupabasePlaceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Place>> fetchByCity(String city) async {
    final rows = await _client
        .from('mst_place')
        .select(
          'id, name, city, area, address, description, price_range, '
          'visit_minutes, photo_url, location, google_place_id, '
          'mst_place_category(category_code, is_primary), '
          'mst_place_attribute(attribute_code), '
          'mst_place_opening_hour(day_of_week, open_time, close_time)',
        )
        .eq('city', city)
        .eq('is_active', true)
        .order('name');

    return [for (final r in rows) _place(r)];
  }

  static Place _place(Map<String, dynamic> r) {
    final point = parseGeoPoint(r['location']);
    if (point == null) {
      throw StateError('Tempat ${r['id']} tidak punya koordinat valid.');
    }
    final categories = (r['mst_place_category'] as List)
        .cast<Map<String, dynamic>>()
      ..sort((a, b) => (b['is_primary'] as bool ? 1 : 0) - (a['is_primary'] as bool ? 1 : 0));
    return Place(
      id: r['id'] as String,
      name: r['name'] as String,
      city: r['city'] as String,
      lat: point.lat,
      lng: point.lng,
      visitMinutes: r['visit_minutes'] as int,
      categoryCodes: [for (final c in categories) c['category_code'] as String],
      attributeCodes: [
        for (final a in (r['mst_place_attribute'] as List).cast<Map<String, dynamic>>())
          a['attribute_code'] as String,
      ],
      openingHours: [
        for (final h in (r['mst_place_opening_hour'] as List).cast<Map<String, dynamic>>())
          OpeningHour(
            dayOfWeek: h['day_of_week'] as int,
            open: Clock.parseDbTime(h['open_time'] as String),
            close: Clock.parseDbTime(h['close_time'] as String),
          ),
      ],
      area: r['area'] as String?,
      address: r['address'] as String?,
      description: r['description'] as String?,
      priceRange: PriceRange.fromDb(r['price_range'] as String?),
      photoUrl: r['photo_url'] as String?,
      googlePlaceId: r['google_place_id'] as String?,
    );
  }
}