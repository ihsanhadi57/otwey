import '../../planner/domain/itinerary.dart';
import '../../planner/domain/leg_mode.dart';

/// Itinerary yang disimpan beserta pilihan moda tiap perpindahan, persis
/// seperti saat user menekan Simpan. Tidak ikut berubah kalau draft diubah.
class SavedTrip {
  const SavedTrip({required this.itinerary, required this.choices, this.id});

  /// Id baris `trx_plan`, null sebelum persist pertama (mode lokal).
  final String? id;
  final Itinerary itinerary;
  final Map<String, LegMode> choices;

  LegMode modeOf(LegEntry leg) => leg.effective(choices[leg.id] ?? leg.recommended);
}