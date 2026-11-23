import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../places/domain/place.dart';
import '../../planner/domain/itinerary.dart';
import '../../planner/domain/leg_mode.dart';
import '../data/origin_store.dart';
import '../domain/origin_point.dart';
import '../domain/plan_pin.dart';
import '../domain/travel_mode.dart';
import '../domain/trip_direction.dart';
import '../domain/trip_draft.dart';
import '../domain/trip_pace.dart';
import '../domain/vibe_catalog.dart';

final tripDraftProvider = NotifierProvider<TripDraftNotifier, TripDraft>(
  TripDraftNotifier.new,
);

/// Satu sumber state untuk semua layar rencana trip (docs/RULES.md).
/// Titik berangkat dan tujuan mulai kosong, diisi user dari data asli.
class TripDraftNotifier extends Notifier<TripDraft> {
  @override
  TripDraft build() => TripDraft.initial(DateTime.now());

  void setDirection(TripDirection direction) {
    state = state.copyWith(direction: direction, clearOrigin: true, clearEdits: true);
    restoreOrigin();
  }

  /// Tukar kota asal dan tujuan. Titik berangkat ikut pindah ke kota asal baru.
  void swapDirection() => setDirection(state.direction.reversed);

  /// Pilih titik berangkat dan simpan di perangkat untuk kota asal ini.
  void setOrigin(OriginPoint origin) {
    state = state.copyWith(origin: origin);
    ref.read(originStoreProvider).save(state.originCity, origin);
  }

  /// Pakai titik berangkat tersimpan untuk kota asal sekarang, kalau belum ada.
  Future<OriginPoint?> restoreOrigin() async {
    final city = state.originCity;
    final saved = await ref.read(originStoreProvider).load(city);
    if (saved != null && state.origin == null && state.originCity == city) {
      state = state.copyWith(origin: saved);
    }
    return saved;
  }

  void setDate(DateTime date) =>
      _setup(state.copyWith(travelDate: DateTime(date.year, date.month, date.day)));

  void setEarliestDeparture(int minutes) =>
      _setup(state.copyWith(earliestDeparture: minutes));

  void setLatestReturn(int minutes) =>
      _setup(state.copyWith(latestReturn: minutes));

  /// Mengembalikan pesan error jika tujuan ditolak, null jika berhasil.
  String? addPin(PlanPin pin) {
    for (final p in state.pins) {
      if (p.overlaps(pin)) return 'Jamnya bentrok sama "${p.name}"';
    }
    _setup(state.copyWith(pins: [...state.pins, pin]));
    return null;
  }

  /// Masukkan tempat dari Jelajah/Wishlist sebagai tujuan bebas jam, prioritas
  /// Kalau sempat (planner boleh melepasnya kalau waktu mepet).
  /// Mengembalikan false kalau tempat sudah ada di rencana.
  bool addPlace(Place place) {
    if (state.pins.any((p) => p.placeId == place.id)) return false;
    state = state.copyWith(clearEdits: true, pins: [
      ...state.pins,
      PlanPin(
        id: 'pin_${place.id}',
        placeId: place.id,
        name: place.name,
        address: place.address,
        lat: place.lat,
        lng: place.lng,
        purpose: PinPurpose.main,
        priority: PinPriority.opsional,
        durationMinutes: place.visitMinutes,
      ),
    ]);
    return true;
  }

  bool hasPlace(String placeId) => state.pins.any((p) => p.placeId == placeId);

  void removePin(String id) =>
      state = state.copyWith(pins: [...state.pins.where((p) => p.id != id)]);

  /// Ganti vibes. Sub kategori di-reset ke default vibes baru.
  void setTripType(String code) => _setup(state.copyWith(
        tripTypeCode: code,
        categoryCodes: VibeCatalog.defaultSubs(code),
      ));

  void toggleCategory(String code) {
    final next = [...state.categoryCodes];
    next.contains(code) ? next.remove(code) : next.add(code);
    _setup(state.copyWith(categoryCodes: next));
  }

  void setBudget(String budget) => _setup(state.copyWith(budget: budget));

  void setWithKids(bool value) => state = state.copyWith(withKids: value);

  void setTravelMode(TravelMode mode) => state = state.copyWith(travelMode: mode);

  /// Atur tempo (jumlah maksimal rekomendasi). Edit hasil sebelumnya di-reset.
  void setMaxStops(int stops) => _setup(state.copyWith(
        maxStops: stops.clamp(TripPace.minStops, TripPace.maxStopsLimit),
      ));

  void setPace(TripPace pace) => setMaxStops(pace.maxStops);

  /// Hapus satu rekomendasi dari hasil [itinerary]. Rekomendasi lain dipertahankan
  /// dengan urutan sama, dan tidak ada pengganti otomatis: sisa waktunya jadi
  /// waktu luang. Planner menghitung ulang jam lewat itineraryProvider.
  void removeRecommendation(Itinerary itinerary, String placeId) {
    final kept = [...itinerary.recommendedPlaceIds.where((id) => id != placeId)];
    state = state.copyWith(
      excludedPlaceIds: {...state.excludedPlaceIds, placeId}.toList(),
      keptPlaceIds: kept,
      maxStops: kept.length,
    );
  }

  /// Tukar satu rekomendasi dengan tempat lain di slot yang sama. Urutan
  /// rekomendasi lain tetap, tempat lama tidak dipilih lagi.
  void swapRecommendation(Itinerary itinerary, String fromId, String toId) {
    final kept = [for (final id in itinerary.recommendedPlaceIds) id == fromId ? toId : id];
    final overrides = {...state.stayOverrides}..remove(fromId);
    state = state.copyWith(
      excludedPlaceIds: {...state.excludedPlaceIds, fromId}.toList(),
      keptPlaceIds: kept,
      maxStops: kept.length,
      stayOverrides: overrides,
    );
  }

  /// Hapus tujuan milik user dari halaman hasil. Rekomendasi yang ada
  /// dipertahankan, sisa waktunya jadi waktu luang (tidak diisi otomatis).
  void removePinFromResult(Itinerary itinerary, String pinId) {
    final kept = itinerary.recommendedPlaceIds;
    state = state.copyWith(
      pins: [...state.pins.where((p) => p.id != pinId)],
      keptPlaceIds: kept,
      maxStops: kept.length,
    );
  }

  /// Atur lama kunjungan satu tempat ([key] = id pin atau id tempat).
  /// Rekomendasi lain dipertahankan supaya urutannya tidak teracak.
  void setStay(Itinerary itinerary, String key, int minutes) {
    final kept = itinerary.recommendedPlaceIds;
    state = state.copyWith(
      stayOverrides: {...state.stayOverrides, key: minutes},
      keptPlaceIds: kept,
      maxStops: kept.length,
    );
  }

  /// Pilih ojol atau transum untuk satu perpindahan. Planner menjadwalkan
  /// ulang dengan moda ini (jam bergeser kalau perlu), tempat lain tetap.
  void setLegMode(Itinerary itinerary, LegEntry leg, LegMode mode) {
    if (!leg.hasPoints) return;
    final kept = itinerary.recommendedPlaceIds;
    state = state.copyWith(
      legModes: {...state.legModes, legKey(leg.fromLat!, leg.fromLng!, leg.toLat!, leg.toLng!): mode},
      keptPlaceIds: kept,
      maxStops: kept.length,
    );
  }

  /// Tambah satu rekomendasi lagi tanpa mengganti yang sudah ada.
  void fillMore(Itinerary itinerary) {
    final kept = itinerary.recommendedPlaceIds;
    state = state.copyWith(
      keptPlaceIds: kept,
      maxStops: (kept.length + 1).clamp(TripPace.minStops, TripPace.maxStopsLimit),
    );
  }

  /// Pindah ke kereta pulang lebih awal yang ditawarkan planner.
  void returnEarlier(Itinerary itinerary) {
    final dep = itinerary.earlierReturnDeparture;
    if (dep == null) return;
    final kept = itinerary.recommendedPlaceIds;
    state = state.copyWith(returnDepartureCap: dep, keptPlaceIds: kept, maxStops: kept.length);
  }

  /// Kembalikan draft sebelumnya (aksi Batal di snackbar).
  void restore(TripDraft draft) => state = draft;

  /// Perubahan setup membuat edit hasil lama tidak berlaku lagi.
  void _setup(TripDraft next) => state = next.copyWith(clearEdits: true);
}
