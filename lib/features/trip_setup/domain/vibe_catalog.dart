/// Satu pilihan vibes (tabel `mst_trip_type`).
class TripVibe {
  const TripVibe(this.code, this.label);

  final String code;
  final String label;
}

/// Satu sub kategori (tabel `mst_category`).
class SubVibe {
  const SubVibe(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;
}

/// Katalog vibes dan sub kategori. Sama dengan seed di migration.
///
/// TODO(hadi): ambil dari `mst_trip_type` dan `mst_trip_type_category` lewat repository.
abstract final class VibeCatalog {
  static const vibes = [
    TripVibe('kulineran', 'Kulineran'),
    TripVibe('alam', 'Healing'),
    TripVibe('budaya', 'Kota'),
    TripVibe('belanja', 'Belanja'),
    TripVibe('keluarga', 'Keluarga'),
    TripVibe('campuran', 'Campur'),
  ];

  static const _subs = <String, List<SubVibe>>{
    'kulineran': [
      SubVibe('makanan_berat', 'Makan Kenyang', 'Nasi, mie, yang bikin kenyang'),
      SubVibe('jajanan', 'Jajan Jajan', 'Cemilan kaki lima, cicip dikit dikit'),
      SubVibe('manis', 'Manis Manis', 'Es krim, kue, dessert'),
      SubVibe('kopi_kafe', 'Ngopi', 'Kafe buat duduk santai'),
      SubVibe('oleh_oleh', 'Oleh Oleh', 'Bawa pulang buat orang rumah'),
    ],
    'alam': [
      SubVibe('alam', 'Healing di Alam', 'Taman, kebun, udara seger'),
      SubVibe('kopi_kafe', 'Ngopi', 'Kafe dengan pemandangan'),
    ],
    'budaya': [
      SubVibe('sejarah_budaya', 'Sejarah & Budaya', 'Gedung tua, museum, cerita lama'),
      SubVibe('seni_kreatif', 'Seni & Kreatif', 'Galeri, ruang kreatif'),
      SubVibe('religi', 'Wisata Religi', 'Masjid dan tempat ibadah bersejarah'),
    ],
    'belanja': [
      SubVibe('belanja', 'Belanja', 'FO, pasar, pusat belanja'),
      SubVibe('oleh_oleh', 'Oleh Oleh', 'Bawa pulang buat orang rumah'),
    ],
    'keluarga': [
      SubVibe('keluarga', 'Bareng Keluarga', 'Seru dan aman buat bocil'),
      SubVibe('alam', 'Healing di Alam', 'Taman, kebun, udara seger'),
    ],
    'campuran': [
      SubVibe('makanan_berat', 'Makan Kenyang', 'Nasi, mie, yang bikin kenyang'),
      SubVibe('sejarah_budaya', 'Sejarah & Budaya', 'Gedung tua, museum, cerita lama'),
      SubVibe('alam', 'Healing di Alam', 'Taman, kebun, udara seger'),
      SubVibe('belanja', 'Belanja', 'FO, pasar, pusat belanja'),
      SubVibe('manis', 'Manis Manis', 'Es krim, kue, dessert'),
    ],
  };

  static List<SubVibe> subsOf(String vibeCode) => _subs[vibeCode] ?? const [];

  static TripVibe byCode(String code) =>
      vibes.firstWhere((v) => v.code == code, orElse: () => vibes.first);

  /// Sub kategori default saat vibes dipilih: dua teratas.
  static List<String> defaultSubs(String vibeCode) =>
      subsOf(vibeCode).take(2).map((s) => s.code).toList();
}
