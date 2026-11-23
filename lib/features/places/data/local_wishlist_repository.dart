import '../domain/wishlist_repository.dart';

/// Wishlist tanpa login: hanya di memori selama aplikasi hidup.
///
/// TODO(hadi): simpan permanen di perangkat (misalnya shared_preferences)
/// supaya wishlist tidak hilang saat aplikasi ditutup.
class LocalWishlistRepository implements WishlistRepository {
  final Set<String> _ids = {};

  @override
  Future<Set<String>> fetchIds() async => {..._ids};

  @override
  Future<void> add(String placeId) async => _ids.add(placeId);

  @override
  Future<void> remove(String placeId) async => _ids.remove(placeId);
}