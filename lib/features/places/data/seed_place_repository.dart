import '../../../core/data/seed_catalog.dart';
import '../../../core/utils/seed_validate.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Mode demo offline: membaca CSV seed yang sama dengan importer Supabase.
class SeedPlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> fetchByCity(String city) async {
    final data = await SeedCatalog.load();
    return placesFrom(data).where((p) => p.city == city).toList();
  }

  /// Pemetaan murni SeedData ke Place, dipakai juga oleh unit test.
  static List<Place> placesFrom(SeedData data) {
    final hours = <String, List<OpeningHour>>{};
    for (final h in data.openingHours) {
      hours
          .putIfAbsent(h.placeKey, () => [])
          .add(OpeningHour(dayOfWeek: h.day, open: h.open, close: h.close));
    }
    return [
      for (final p in data.places)
        Place(
          id: p.key,
          name: p.name,
          city: p.city,
          lat: p.lat,
          lng: p.lng,
          visitMinutes: p.visitMinutes,
          categoryCodes: p.categories,
          attributeCodes: p.attributes,
          openingHours: hours[p.key] ?? const [],
          area: p.area.isEmpty ? null : p.area,
          address: p.address.isEmpty ? null : p.address,
          description: p.description.isEmpty ? null : p.description,
          priceRange: PriceRange.fromDb(p.priceRange),
          googlePlaceId: p.googlePlaceId.isEmpty ? null : p.googlePlaceId,
        ),
    ];
  }
}