import 'itinerary.dart';

export 'itinerary.dart' show PlanStatus;

/// Jenis item timeline. Sama dengan enum `plan_item_type`.
enum PlanItemType { whoosh, feeder, travel, place, buffer }

/// Satu baris timeline (tabel `trx_plan_item`). Jam dalam menit sejak tengah malam.
class PlanItem {
  const PlanItem({
    required this.type,
    required this.start,
    required this.end,
    this.title,
    this.placeId,
    this.pinId,
    this.whooshTripId,
    this.feederScheduleId,
    this.travelMode,
    this.isLocked = false,
    this.note,
  });

  final PlanItemType type;
  final int start;
  final int end;
  final String? title;
  final String? placeId;
  final String? pinId;
  final int? whooshTripId;
  final int? feederScheduleId;
  final String? travelMode;
  final bool isLocked;
  final String? note;

  int get minutes => end - start;
}

/// Hasil planner.
class PlanResult {
  const PlanResult({
    required this.status,
    required this.items,
    this.droppedPinIds = const [],
    this.blockingPinId,
    this.freeMinutes = 0,
    this.minutesUntilLeave,
    this.itinerary,
  });

  final PlanStatus status;
  final List<PlanItem> items;

  /// Tujuan yang dilepas karena tidak muat (Penting atau Kalau sempat).
  final List<String> droppedPinIds;

  /// Tujuan Wajib yang membuat rencana tidak bisa dibuat. Null jika aman.
  final String? blockingPinId;

  final int freeMinutes;

  /// Sisa menit sebelum harus berangkat ke stasiun pulang, untuk status mepet.
  final int? minutesUntilLeave;

  /// Timeline siap tampil. Null jika [status] impossible.
  final Itinerary? itinerary;
}
