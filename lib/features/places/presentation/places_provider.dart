import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../trip_setup/domain/trip_direction.dart';
import '../data/seed_place_repository.dart';
import '../data/supabase_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabasePlaceRepository(ref.watch(supabaseClientProvider));
  }
  return SeedPlaceRepository();
});

/// Semua tempat di kota demo. Supabase gagal → fallback CSV seed;
/// seed juga gagal (CSV masih template) → error, tidak mengarang data.
final placesProvider = FutureProvider<List<Place>>((ref) async {
  final repo = ref.watch(placeRepositoryProvider);
  final cities = TripDirection.values.map((d) => d.destinationCity).toSet();
  try {
    return await _fetchCities(repo, cities).timeout(const Duration(seconds: 8));
  } catch (_) {
    if (repo is SeedPlaceRepository) rethrow;
    return _fetchCities(SeedPlaceRepository(), cities);
  }
});

Future<List<Place>> _fetchCities(PlaceRepository repo, Set<String> cities) async {
  final lists = await Future.wait(cities.map(repo.fetchByCity));
  return [for (final list in lists) ...list];
}

/// Tempat di kota tertentu, ikut status loading/error [placesProvider].
final placesInCityProvider = Provider.family<AsyncValue<List<Place>>, String>(
  (ref, city) => ref
      .watch(placesProvider)
      .whenData((all) => all.where((p) => p.city == city).toList()),
);

/// Satu tempat berdasarkan id. Null kalau tidak ditemukan.
final placeByIdProvider = Provider.family<AsyncValue<Place?>, String>(
  (ref, id) => ref.watch(placesProvider).whenData<Place?>((all) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }),
);

/// Jumlah tempat pilihan yang tampil di Beranda (pintasan ke Jelajah).
const featuredLimit = 6;

/// Tempat pilihan di kota tertentu, urut skor kurasi lalu nama.
///
/// TODO(hadi): belum ada data rating. Kalau rating sudah ada di mst_place,
/// urutkan pakai rating; sekarang pakai atribut kurasi (legendaris, spot foto)
/// dan kelengkapan data (jam buka, deskripsi).
final featuredPlacesProvider = Provider.family<AsyncValue<List<Place>>, String>(
  (ref, city) => ref.watch(placesInCityProvider(city)).whenData((places) {
    final sorted = [...places]..sort((a, b) {
        final byScore = featuredScore(b).compareTo(featuredScore(a));
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });
    return sorted.take(featuredLimit).toList();
  }),
);

int featuredScore(Place p) =>
    (p.attributeCodes.contains('legendaris') ? 4 : 0) +
    (p.attributeCodes.contains('spot_foto') ? 2 : 0) +
    (p.openingHours.isNotEmpty ? 1 : 0) +
    ((p.description ?? '').length > 60 ? 1 : 0);
