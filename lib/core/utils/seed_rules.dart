/// Konstanta validasi seed. Selaras dengan seed master di
/// supabase/migrations/20261118000000_init.sql; kalau master berubah, perbarui sini.
library;

const masterCategories = {
  'makanan_berat', 'jajanan', 'manis', 'kopi_kafe', 'makanan_barat', 'oleh_oleh',
  'alam', 'sejarah_budaya', 'belanja', 'seni_kreatif', 'religi', 'keluarga',
};

const masterAttributes = {
  'indoor', 'outdoor', 'cocok_hujan', 'ramah_anak', 'halal', 'legendaris',
  'spot_foto', 'budget_murah', 'budget_sedang', 'budget_mahal',
};

const masterStations = {'HLM', 'KRW', 'PDL', 'TGL', 'BD', 'CMI'};

const transportModes = {
  'whoosh', 'ka_feeder', 'commuter_line', 'damri', 'bus',
  'walk', 'drive', 'two_wheeler', 'transit',
};

const tripDirections = {'jakarta_to_bandung', 'bandung_to_jakarta'};

const accessDirections = {'to_station', 'from_station'};

const priceRanges = {'murah', 'sedang', 'mahal'};

const dataSources = {'google', 'osm', 'foursquare', 'manual'};

/// Batas kota untuk validasi koordinat (perkiraan bbox administratif).
class CityBounds {
  const CityBounds(this.latMin, this.latMax, this.lngMin, this.lngMax);

  final double latMin;
  final double latMax;
  final double lngMin;
  final double lngMax;

  bool contains(double lat, double lng) =>
      lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
}

const cityBounds = {
  'Bandung': CityBounds(-7.10, -6.75, 107.45, 107.80),
  'Jakarta': CityBounds(-6.40, -6.05, 106.60, 107.10),
};

/// Penanda baris template yang belum diisi. File berisi ini ditolak.
const placeholderMarkers = ['(isi)', 'contoh-sumber', 'Deskripsi 1 sampai 3 kalimat'];

bool hasPlaceholder(String value) {
  final v = value.toLowerCase();
  for (final m in placeholderMarkers) {
    if (v.contains(m.toLowerCase())) return true;
  }
  return false;
}

/// 'HH:MM' menjadi menit sejak tengah malam. Null kalau bukan jam valid.
int? parseClock(String value) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// Pemisah daftar kode dalam satu sel CSV (kategori, atribut).
List<String> splitCodes(String value) => value
    .split(';')
    .map((c) => c.trim())
    .where((c) => c.isNotEmpty)
    .toList();