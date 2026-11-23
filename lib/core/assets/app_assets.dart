/// Path aset brand. Sumber dan aturan pakai: docs/BRAND.md.
abstract final class AppAssets {
  static const _brand = 'assets/brand';

  static const logo = '$_brand/logo.svg';
  static const logoOnDark = '$_brand/logo_on_dark.svg';
  static const logoMark = '$_brand/logo_mark.svg';

  static String oti(OtiMood mood) => '$_brand/oti_${mood.name}.svg';
}

/// Ekspresi maskot Oti. Nama enum = akhiran nama file `oti_<mood>.svg`.
enum OtiMood {
  /// OTW!, sapaan, onboarding, sukses.
  happy,

  /// Mepet nih, waktu tinggal sedikit.
  mepet,

  /// Sip, aman, rencana tersimpan atau status aman.
  sip,

  /// Nanti aja, empty state atau belum ada rencana.
  zzz,
}
