/// Kisaran harga. Sama dengan enum `price_range`.
enum PriceRange {
  murah('murah'),
  sedang('sedang'),
  mahal('mahal');

  const PriceRange(this.dbValue);

  final String dbValue;

  static PriceRange? fromDb(String? value) {
    if (value == null) return null;
    for (final p in values) {
      if (p.dbValue == value) return p;
    }
    return null;
  }
}

/// Jam buka satu hari. Boleh lebih dari satu per hari. Menit sejak tengah malam.
class OpeningHour {
  const OpeningHour({
    required this.dayOfWeek,
    required this.open,
    required this.close,
  });

  /// ISO 1 Senin sampai 7 Minggu, sama dengan `DateTime.weekday`.
  final int dayOfWeek;
  final int open;
  final int close;

  bool covers(int from, int to) => open <= from && close >= to;
}

/// Tempat dari `mst_place`.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.visitMinutes,
    required this.categoryCodes,
    required this.attributeCodes,
    required this.openingHours,
    this.area,
    this.address,
    this.description,
    this.priceRange,
    this.photoUrl,
    this.googlePlaceId,
  });

  final String id;
  final String name;
  final String city;
  final String? area;
  final String? address;
  final double lat;
  final double lng;
  final String? description;
  final PriceRange? priceRange;
  final int visitMinutes;
  final String? photoUrl;

  /// place_id Google, diisi Edge Function place-lookup. Null kalau belum dicari.
  final String? googlePlaceId;
  final List<String> categoryCodes;
  final List<String> attributeCodes;
  final List<OpeningHour> openingHours;

  /// True jika tempat buka sepanjang [from] sampai [to] pada [dayOfWeek].
  bool isOpen(int dayOfWeek, int from, int to) => openingHours
      .any((h) => h.dayOfWeek == dayOfWeek && h.covers(from, to));
}
