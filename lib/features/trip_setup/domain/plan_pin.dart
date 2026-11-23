/// Prioritas tujuan user. [rank] kecil = didahulukan planner.
/// Nilai [dbValue] sama dengan enum `pin_priority` di database.
enum PinPriority {
  wajib('wajib', 0),
  penting('penting', 1),
  opsional('opsional', 2);

  const PinPriority(this.dbValue, this.rank);

  final String dbValue;
  final int rank;

  static PinPriority fromDb(String value) =>
      values.firstWhere((p) => p.dbValue == value);
}

/// Keperluan tujuan. Nilai [dbValue] sama dengan enum `pin_purpose`.
enum PinPurpose {
  kerja('kerja'),
  janji('janji'),
  main('main'),
  lainnya('lainnya');

  const PinPurpose(this.dbValue);

  final String dbValue;

  static PinPurpose fromDb(String value) =>
      values.firstWhere((p) => p.dbValue == value);
}

/// Tujuan yang dimasukkan sendiri oleh user (tabel `trx_plan_pin`).
///
/// Jam tetap: [fixedStart] dan [fixedEnd] terisi.
/// Bebas jam: keduanya null dan [durationMinutes] terisi.
/// Semua jam dalam menit sejak tengah malam.
class PlanPin {
  const PlanPin({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.purpose,
    required this.priority,
    this.placeId,
    this.address,
    this.fixedStart,
    this.fixedEnd,
    this.durationMinutes,
    this.note,
  }) : assert(
          (fixedStart != null && fixedEnd != null) || durationMinutes != null,
          'Isi jam tetap atau durasi',
        );

  final String id;
  final String? placeId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final PinPurpose purpose;
  final PinPriority priority;
  final int? fixedStart;
  final int? fixedEnd;
  final int? durationMinutes;
  final String? note;

  bool get isFixedTime => fixedStart != null && fixedEnd != null;

  /// Lama di lokasi dalam menit.
  int get stayMinutes =>
      isFixedTime ? fixedEnd! - fixedStart! : durationMinutes!;

  /// Default prioritas (PRD FR-14): jam tetap + kerjaan = Wajib, lainnya Penting.
  static PinPriority defaultPriority({
    required PinPurpose purpose,
    required bool isFixedTime,
  }) =>
      isFixedTime && purpose == PinPurpose.kerja
          ? PinPriority.wajib
          : PinPriority.penting;

  /// True jika dua tujuan berjam tetap saling tumpang tindih (PRD FR-16).
  bool overlaps(PlanPin other) {
    if (!isFixedTime || !other.isFixedTime) return false;
    return fixedStart! < other.fixedEnd! && other.fixedStart! < fixedEnd!;
  }
}
