import '../../planner/domain/leg_mode.dart';
import 'saved_trip.dart';

abstract interface class SavedTripRepository {
  /// Trip tersimpan terakhir milik user, null kalau belum ada.
  Future<SavedTrip?> fetch();

  /// Simpan atau perbarui trip, mengembalikan id baris.
  Future<String> save(SavedTrip trip);

  Future<void> updateChoices(String id, Map<String, LegMode> choices);

  Future<void> clear();
}