import 'place.dart';

/// Filter tempat di Jelajah. Murni, tanpa UI, supaya bisa diuji.
class PlaceFilter {
  const PlaceFilter({
    this.query = '',
    this.openNow = false,
    this.maxBudget,
    this.attributes = const {},
    this.onlySaved = false,
  });

  /// Teks pencarian: nama, area, alamat. Kosong = semua.
  final String query;
  final bool openNow;

  /// Batas harga (`murah`, `sedang`, `mahal`). Null = semua.
  final String? maxBudget;

  /// Atribut yang wajib ada semua, misalnya halal, indoor.
  final Set<String> attributes;
  final bool onlySaved;

  /// Jumlah filter aktif selain pencarian (untuk badge tombol filter).
  int get activeCount => (openNow ? 1 : 0) + (maxBudget != null ? 1 : 0) + attributes.length + (onlySaved ? 1 : 0);

  bool get searching => query.trim().isNotEmpty;

  PlaceFilter copyWith({
    String? query,
    bool? openNow,
    String? maxBudget,
    bool clearBudget = false,
    Set<String>? attributes,
    bool? onlySaved,
  }) =>
      PlaceFilter(
        query: query ?? this.query,
        openNow: openNow ?? this.openNow,
        maxBudget: clearBudget ? null : (maxBudget ?? this.maxBudget),
        attributes: attributes ?? this.attributes,
        onlySaved: onlySaved ?? this.onlySaved,
      );

  PlaceFilter cleared() => PlaceFilter(query: query);

  /// Terapkan filter. Saat mencari, kategori vibes diabaikan supaya tempat
  /// yang dicari tetap ketemu walau di luar vibes yang dipilih.
  List<Place> apply(
    List<Place> places, {
    required Set<String> categories,
    required Set<String> saved,
    required DateTime now,
  }) {
    final q = _norm(query);
    final minute = now.hour * 60 + now.minute;
    final budget = PriceRange.fromDb(maxBudget);
    return [
      for (final p in places)
        if ((q.isNotEmpty
                ? _norm('${p.name} ${p.area ?? ''} ${p.address ?? ''}').contains(q)
                : p.categoryCodes.any(categories.contains)) &&
            (!openNow || p.isOpen(now.weekday, minute, minute + 1)) &&
            (budget == null || p.priceRange == null || p.priceRange!.index <= budget.index) &&
            attributes.every(p.attributeCodes.contains) &&
            (!onlySaved || saved.contains(p.id)))
          p,
    ];
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  @override
  bool operator ==(Object other) =>
      other is PlaceFilter &&
      other.query == query &&
      other.openNow == openNow &&
      other.maxBudget == maxBudget &&
      other.onlySaved == onlySaved &&
      other.attributes.length == attributes.length &&
      other.attributes.containsAll(attributes);

  @override
  int get hashCode => Object.hash(
        query,
        openNow,
        maxBudget,
        onlySaved,
        Object.hashAllUnordered(attributes),
      );
}
