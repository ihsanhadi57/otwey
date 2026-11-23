import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/edge_function.dart';
import '../domain/google_place_details.dart';

/// Detail tempat langsung dari Google lewat Edge Function `place-details`.
class PlaceDetailsRepository {
  const PlaceDetailsRepository(this._fn);

  final EdgeFunctions _fn;

  Future<GooglePlaceDetails?> fetch(String googlePlaceId) async {
    final data = await _fn.call('place-details', {'placeId': googlePlaceId});
    if (data is! Map || data['error'] != null) return null;
    return GooglePlaceDetails.fromJson(data.cast<String, dynamic>());
  }
}

final placeDetailsRepositoryProvider = Provider<PlaceDetailsRepository?>((ref) {
  final fn = ref.watch(edgeFunctionsProvider);
  return fn == null ? null : PlaceDetailsRepository(fn);
});

/// Detail Google satu tempat. Null kalau Supabase belum aktif atau gagal.
final googlePlaceDetailsProvider = FutureProvider.autoDispose.family<GooglePlaceDetails?, String>((ref, id) async {
  final repo = ref.watch(placeDetailsRepositoryProvider);
  if (repo == null) return null;
  return repo.fetch(id);
});
