/// Rute transportasi umum langsung dari Edge Function `transit-route`
/// (Google Routes API mode TRANSIT). Hanya untuk tampilan: planner tetap
/// deterministik dan tidak memakai data ini untuk menghitung jadwal.
library;

/// Moda satu langkah transum. Sama dengan nilai `mode` dari Edge Function.
enum TransitMode {
  walk,
  bus,
  subway,
  lightRail,
  rail,
  other;

  static TransitMode fromJson(Object? v) => switch (v) {
        'walk' => walk,
        'bus' => bus,
        'subway' => subway,
        'light_rail' => lightRail,
        'rail' => rail,
        _ => other,
      };
}

/// Satu langkah: jalan kaki, atau naik satu jalur (MRT, LRT, TransJakarta, KRL).
class TransitLegStep {
  const TransitLegStep({
    required this.mode,
    required this.minutes,
    this.distanceMeters,
    this.line,
    this.lineShort,
    this.colorHex,
    this.headsign,
    this.from,
    this.to,
    this.departAt,
    this.arriveAt,
    this.stops,
  });

  final TransitMode mode;
  final int minutes;
  final int? distanceMeters;

  /// Nama jalur, misalnya "MRT Jakarta Lin Utara-Selatan" atau "Koridor 1".
  final String? line;
  final String? lineShort;

  /// Warna jalur dari Google ("#RRGGBB"), kalau ada.
  final String? colorHex;
  final String? headsign;
  final String? from;
  final String? to;

  /// Jam naik dan turun, menit sejak tengah malam WIB.
  final int? departAt;
  final int? arriveAt;
  final int? stops;

  bool get isWalk => mode == TransitMode.walk;

  /// Label singkat untuk badge: nama pendek kalau ada, selain itu nama jalur.
  String? get badge => (lineShort?.isNotEmpty ?? false) ? lineShort : line;

  /// Warna jalur sebagai ARGB, null kalau tidak ada atau tidak valid.
  int? get colorArgb {
    final hex = colorHex?.replaceFirst('#', '');
    if (hex == null || hex.length != 6) return null;
    final v = int.tryParse(hex, radix: 16);
    return v == null ? null : 0xFF000000 | v;
  }

  factory TransitLegStep.fromJson(Map<String, dynamic> j) => TransitLegStep(
        mode: TransitMode.fromJson(j['mode']),
        minutes: (j['minutes'] as num?)?.round() ?? 0,
        distanceMeters: (j['distanceMeters'] as num?)?.round(),
        line: j['line'] as String?,
        lineShort: j['lineShort'] as String?,
        colorHex: j['color'] as String?,
        headsign: j['headsign'] as String?,
        from: j['from'] as String?,
        to: j['to'] as String?,
        departAt: wibMinutes(j['departAt']),
        arriveAt: wibMinutes(j['arriveAt']),
        stops: (j['stops'] as num?)?.round(),
      );
}

/// Rute lengkap. [steps] kosong = Google tidak menemukan rute transum.
class TransitRoute {
  const TransitRoute({required this.minutes, required this.steps, this.distanceMeters});

  final int minutes;
  final int? distanceMeters;
  final List<TransitLegStep> steps;

  /// Ada minimal satu langkah naik kendaraan (bukan cuma jalan kaki).
  bool get hasTransit => steps.any((s) => !s.isWalk);

  /// Langkah naik kendaraan saja.
  Iterable<TransitLegStep> get rides => steps.where((s) => !s.isWalk);

  /// Null kalau payload tidak berisi rute transum yang bisa dipakai.
  static TransitRoute? fromJson(Object? json) {
    if (json is! Map) return null;
    final raw = json['steps'];
    if (raw is! List || raw.isEmpty) return null;
    final steps = [for (final s in raw) if (s is Map) TransitLegStep.fromJson(s.cast<String, dynamic>())];
    final total = (json['minutes'] as num?)?.round() ?? steps.fold<int>(0, (a, s) => a + s.minutes);
    final route = TransitRoute(
      minutes: total,
      distanceMeters: (json['distanceMeters'] as num?)?.round(),
      steps: steps,
    );
    return route.hasTransit ? route : null;
  }
}

/// Selisih WIB dari UTC. Jakarta dan Bandung sama-sama WIB.
const wibOffset = Duration(hours: 7);

/// Waktu ISO 8601 ke menit sejak tengah malam WIB, null kalau tidak valid.
int? wibMinutes(Object? iso) {
  if (iso is! String) return null;
  final t = DateTime.tryParse(iso);
  if (t == null) return null;
  final wib = t.toUtc().add(wibOffset);
  return wib.hour * 60 + wib.minute;
}

/// Jam berangkat [minutes] (sejak tengah malam WIB) pada [date] sebagai ISO 8601 +07:00.
String wibIso(DateTime date, int minutes) {
  String two(int v) => v.toString().padLeft(2, '0');
  final m = minutes.clamp(0, 24 * 60 - 1);
  return '${date.year}-${two(date.month)}-${two(date.day)}T${two(m ~/ 60)}:${two(m % 60)}:00+07:00';
}
