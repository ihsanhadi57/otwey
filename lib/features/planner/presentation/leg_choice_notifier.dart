import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../domain/itinerary.dart';
import '../domain/leg_mode.dart';
import 'itinerary_provider.dart';

final legChoiceProvider = NotifierProvider<LegChoiceNotifier, Map<String, LegMode>>(
  LegChoiceNotifier.new,
);

/// Moda tiap perpindahan di rencana yang sedang disusun. Sumbernya planner
/// (preferensi "Pindah antar tempat" atau pilihan user per perpindahan).
/// Mengganti moda menjadwal ulang rencana, jadi jam tetap bisa dijalani.
class LegChoiceNotifier extends Notifier<Map<String, LegMode>> {
  @override
  Map<String, LegMode> build() {
    final itinerary = ref.watch(itineraryProvider).value;
    return {for (final leg in itinerary?.legs ?? const <LegEntry>[]) leg.id: leg.recommended};
  }

  void choose(String legId, LegMode mode) {
    final itinerary = ref.read(itineraryProvider).value;
    if (itinerary == null) return;
    for (final leg in itinerary.legs) {
      if (leg.id != legId) continue;
      state = {...state, legId: mode};
      ref.read(tripDraftProvider.notifier).setLegMode(itinerary, leg, mode);
      return;
    }
  }
}
