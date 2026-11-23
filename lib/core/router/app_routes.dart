abstract final class AppRoutes {
  static const onboarding = '/';

  // Tab utama (navbar).
  static const home = '/beranda';
  static const explore = '/jelajah';
  static const trips = '/trip';
  static const account = '/akun';

  // Alur bikin trip.
  static const origin = '/titik';
  static const originMap = '/titik/peta';
  static const wishlist = '/wishlist';
  static const plan = '/rencana';
  static const addPin = '/rencana/tujuan';
  static const generating = '/menyusun';
  static const result = '/hasil';
  static const live = '/jalan';

  /// Itinerary yang sudah disimpan (baca saja, pilihan moda ikut tersimpan).
  static const savedPlan = '/trip/rencana';
  /// Detail tempat untuk menjelajah (dari Beranda, Jelajah, Wishlist).
  static String place(String id) => '/tempat/$id';
  static const placePattern = '/tempat/:id';

  /// Detail tempat yang sudah ada di draft itinerary (tukar tempat, alternatif).
  static String stop(String placeId) => '/hasil/tempat/$placeId';
  static const stopPattern = '/hasil/tempat/:id';

  // Wizard lama (v1). Tidak dipakai di router, dihapus setelah halaman lamanya dihapus.
  static const direction = '/arah';
  static const time = '/waktu';
  static const pins = '/tujuan';
  static const vibes = '/vibes';
  static const saved = '/tersimpan';
}
