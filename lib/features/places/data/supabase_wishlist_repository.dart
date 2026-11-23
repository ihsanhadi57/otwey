import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/wishlist_repository.dart';

/// Wishlist tersimpan di `trx_wishlist`, terikat user yang login (RLS owner).
class SupabaseWishlistRepository implements WishlistRepository {
  SupabaseWishlistRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Wishlist butuh login dulu.');
    return uid;
  }

  @override
  Future<Set<String>> fetchIds() async {
    final rows = await _client
        .from('trx_wishlist')
        .select('place_id')
        .eq('user_id', _userId);
    return {for (final r in rows) r['place_id'] as String};
  }

  @override
  Future<void> add(String placeId) async {
    await _client.from('trx_wishlist').upsert(
      {'user_id': _userId, 'place_id': placeId},
      onConflict: 'user_id,place_id',
    );
  }

  @override
  Future<void> remove(String placeId) async {
    await _client
        .from('trx_wishlist')
        .delete()
        .eq('user_id', _userId)
        .eq('place_id', placeId);
  }
}