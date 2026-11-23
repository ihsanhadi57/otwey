/// Konfigurasi aplikasi yang bukan rahasia.
///
/// Nama aplikasi hanya ditulis di sini, jangan di tempat lain.
abstract final class AppConfig {
  static const appName = 'OTWEY';

  /// Batas tujuan yang boleh ditambahkan user dalam satu trip (PRD FR-10).
  static const maxPins = 5;

  /// Berapa hari ke depan user boleh merencanakan trip (PRD FR-02).
  static const maxDaysAhead = 30;

  /// Tile peta OpenStreetMap. Wajib atribusi, dan tidak untuk trafik besar
  /// (https://operations.osmfoundation.org/policies/tiles/).
  /// TODO(hadi): ganti ke penyedia tile berkunci (MapTiler) atau
  /// google_maps_flutter sebelum rilis publik.
  static const mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identitas aplikasi yang dikirim ke server tile (aturan pakai OSM).
  static const mapUserAgentPackage = 'com.kcic.hackathon.otwey';

  /// Titik tengah peta per kota saat belum ada titik untuk ditampilkan.
  static const cityCenters = <String, ({double lat, double lng})>{
    'Bandung': (lat: -6.9218, lng: 107.6070), // Alun-alun Bandung
    'Jakarta': (lat: -6.1754, lng: 106.8272), // Monas
  };

  static ({double lat, double lng}) cityCenter(String city) =>
      cityCenters[city] ?? cityCenters.values.first;
}
