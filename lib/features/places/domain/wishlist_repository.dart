abstract interface class WishlistRepository {
  /// Id tempat yang disimpan user saat ini.
  Future<Set<String>> fetchIds();

  Future<void> add(String placeId);

  Future<void> remove(String placeId);
}