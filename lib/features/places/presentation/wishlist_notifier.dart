import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/env.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../data/local_wishlist_repository.dart';
import '../data/supabase_wishlist_repository.dart';
import '../domain/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  if (Env.hasSupabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client.auth.currentUser != null) {
      return SupabaseWishlistRepository(client);
    }
  }
  return LocalWishlistRepository();
});

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, Set<String>>(
  WishlistNotifier.new,
);

/// Id tempat yang disimpan user. Supabase kalau login, lokal kalau tidak.
class WishlistNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(wishlistRepositoryProvider).fetchIds();

  bool contains(String placeId) =>
      (state.value ?? const <String>{}).contains(placeId);

  /// Mengembalikan true kalau tempat jadi tersimpan, false kalau dihapus.
  /// Optimis: state berubah dulu, gagal simpan dibatalkan dan dilempar ulang.
  Future<bool> toggle(String placeId) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final current = state.value ?? const <String>{};
    final added = !current.contains(placeId);
    final next = {...current};
    added ? next.add(placeId) : next.remove(placeId);
    state = AsyncData(next);
    try {
      added ? await repo.add(placeId) : await repo.remove(placeId);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
    return added;
  }
}

/// Toggle wishlist plus snackbar umpan balik, dipakai semua layar tempat.
Future<void> toggleWishlist(
  BuildContext context,
  WidgetRef ref,
  String placeId, {
  bool withUndo = false,
}) async {
  try {
    final added = await ref.read(wishlistProvider.notifier).toggle(placeId);
    if (!context.mounted) return;
    showOtwSnackBar(
      context,
      kind: OtwSnackKind.info,
      message: added ? AppCopy.savedToWishlist : AppCopy.removedFromWishlist,
      actionLabel: withUndo ? AppCopy.undo : null,
      onAction: withUndo ? () => toggleWishlist(context, ref, placeId) : null,
    );
  } catch (_) {
    if (!context.mounted) return;
    showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
  }
}