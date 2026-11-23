/// Arah rute akses stasiun, sama dengan enum `access_direction`.
enum AccessDirection {
  toStation('to_station'),
  fromStation('from_station');

  const AccessDirection(this.dbValue);

  final String dbValue;

  static AccessDirection fromDb(String value) =>
      values.firstWhere((d) => d.dbValue == value);
}

/// Satu langkah rute akses dari `mst_access_step`.
class AccessStep {
  const AccessStep({
    required this.seq,
    required this.mode,
    required this.minutes,
    required this.fare,
    this.service,
    this.corridor,
    this.fromStop,
    this.toStop,
    this.operatingHours,
  });

  final int seq;

  /// Nilai enum `transport_mode`, misalnya walk, commuter_line, bus.
  final String mode;
  final int minutes;
  final int fare;
  final String? service;
  final String? corridor;
  final String? fromStop;
  final String? toStop;
  final String? operatingHours;
}

/// Rute akses dari/ke stasiun dari `mst_access_route` + langkahnya.
class AccessRoute {
  const AccessRoute({
    required this.code,
    required this.stationCode,
    required this.direction,
    required this.name,
    required this.steps,
    this.anchorLat,
    this.anchorLng,
  });

  /// Ujung rute di sisi kota (contoh: Stasiun LRT Dukuh Atas). Tanpa titik ini
  /// planner tidak bisa menilai rute cocok dengan asal user, jadi tidak dipakai.
  final double? anchorLat;
  final double? anchorLng;

  bool get hasAnchor => anchorLat != null && anchorLng != null;

  final String code;
  final String stationCode;
  final AccessDirection direction;
  final String name;
  final List<AccessStep> steps;

  int get totalMinutes => steps.fold(0, (sum, s) => sum + s.minutes);

  int get totalFare => steps.fold(0, (sum, s) => sum + s.fare);
}