/// Jenis titik berangkat, menentukan ikon di daftar.
enum OriginKind { home, work, station, other, current }

/// Titik berangkat user di kota asal (bukan stasiun kereta cepat).
/// Dari titik ini planner mengarahkan ke stasiun keberangkatan.
class OriginPoint {
  const OriginPoint({
    required this.id,
    required this.label,
    required this.address,
    required this.kind,
    this.etaMinMinutes,
    this.etaMaxMinutes,
    this.lat,
    this.lng,
  });

  final String id;
  final String label;
  final String address;
  final OriginKind kind;

  /// Perkiraan waktu ke stasiun keberangkatan. Null kalau belum ada data
  /// waktu tempuh; jangan mengarang angka (docs/RULES.md bagian data).
  final int? etaMinMinutes;
  final int? etaMaxMinutes;
  final double? lat;
  final double? lng;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'kind': kind.name,
        'lat': lat,
        'lng': lng,
      };

  static OriginPoint? fromJson(Object? j) {
    if (j is! Map) return null;
    return OriginPoint(
      id: j['id'] as String? ?? 'saved',
      label: j['label'] as String? ?? '',
      address: j['address'] as String? ?? '',
      kind: OriginKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => OriginKind.other),
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
    );
  }

  /// Label ringkas untuk kartu, misalnya "Rumah · Tebet Barat".
  String get shortLabel {
    final area = address.split(',').last.trim();
    return '$label · $area';
  }
}
