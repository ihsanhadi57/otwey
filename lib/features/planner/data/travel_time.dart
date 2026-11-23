import '../../../core/utils/geo.dart';

/// Fungsi waktu tempuh sinkron (menit) antar dua koordinat.
typedef TravelMinutesFn = int Function(
    double fromLat, double fromLng, double toLat, double toLng);

/// Kecepatan rata rata ojol dalam kota untuk estimasi (km/jam).
const _cityKmh = 20.0;
const _roadFactor = 1.4;

/// Estimasi waktu tempuh (PRD 8.4): cache dulu, lalu jarak jalan ×1.4.
///
/// TODO(hadi): isi [cache] dari `cache_travel_time` yang diisi Edge Function
/// Routes/ORS. Tanpa cache, hasil adalah perkiraan, bukan waktu tempuh asli.
TravelMinutesFn estimateTravelMinutes({Map<String, int> cache = const {}}) {
  return (fromLat, fromLng, toLat, toLng) {
    final key = _key(fromLat, fromLng, toLat, toLng);
    final cached = cache[key];
    if (cached != null) return cached;
    final km = haversineKm(fromLat, fromLng, toLat, toLng) * _roadFactor;
    final minutes = (km / _cityKmh * 60).round();
    return minutes < 1 ? 1 : minutes;
  };
}

String _key(double aLat, double aLng, double bLat, double bLng) =>
    '${aLat.toStringAsFixed(5)},${aLng.toStringAsFixed(5)}|'
    '${bLat.toStringAsFixed(5)},${bLng.toStringAsFixed(5)}';