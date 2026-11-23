import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../planner/domain/itinerary.dart';
import '../../planner/domain/leg_mode.dart';
import '../data/local_saved_trip_repository.dart';
import '../data/supabase_saved_trip_repository.dart';
import '../domain/saved_trip.dart';
import '../domain/saved_trip_repository.dart';

final savedTripRepositoryProvider = Provider<SavedTripRepository>((ref) {
  if (Env.hasSupabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client.auth.currentUser != null) {
      return SupabaseSavedTripRepository(client);
    }
  }
  return LocalSavedTripRepository();
});

final savedTripProvider = AsyncNotifierProvider<SavedTripNotifier, SavedTrip?>(
  SavedTripNotifier.new,
);

/// Trip yang sudah disimpan user, dipulihkan dari repository saat app dibuka.
/// Satu trip aktif untuk demo; pilihan moda ikut dipersist.
class SavedTripNotifier extends AsyncNotifier<SavedTrip?> {
  @override
  Future<SavedTrip?> build() => ref.watch(savedTripRepositoryProvider).fetch();

  Future<void> save(Itinerary itinerary, Map<String, LegMode> choices) async {
    final repo = ref.read(savedTripRepositoryProvider);
    final previous = state.value;
    final next = SavedTrip(id: previous?.id, itinerary: itinerary, choices: {...choices});
    state = AsyncData(next);
    try {
      final id = await repo.save(next);
      state = AsyncData(SavedTrip(id: id, itinerary: itinerary, choices: {...choices}));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Ganti moda satu perpindahan di trip tersimpan. Trip tersimpan tidak
  /// dijadwal ulang, jadi moda yang membuat telat ke langkah berikutnya
  /// ditolak (false). Pilihan yang valid dipersist.
  Future<bool> choose(String legId, LegMode mode) async {
    final s = state.value;
    if (s == null) return false;
    if (!s.itinerary.legFits(legId, mode)) return false;
    final next = SavedTrip(id: s.id, itinerary: s.itinerary, choices: {...s.choices, legId: mode});
    state = AsyncData(next);
    try {
      final repo = ref.read(savedTripRepositoryProvider);
      if (next.id != null) {
        await repo.updateChoices(next.id!, next.choices);
      } else {
        await repo.save(next);
      }
    } catch (_) {
      state = AsyncData(s);
      rethrow;
    }
    return true;
  }

  Future<void> clear() async {
    final previous = state.value;
    state = const AsyncData(null);
    try {
      await ref.read(savedTripRepositoryProvider).clear();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}