import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/utils/geo.dart';
import '../data/address_search.dart';
import '../domain/origin_point.dart';
import '../domain/trip_direction.dart';
import 'trip_draft_notifier.dart';

/// Hasil memakai lokasi sekarang sebagai titik berangkat.
enum CurrentOriginResult { ok, outsideCity, denied, deniedForever, serviceOff, failed }

final currentOriginProvider = Provider<CurrentOriginController>(CurrentOriginController.new);

/// Isi titik berangkat dari GPS: minta izin bila perlu, cari nama jalan,
/// lalu simpan sebagai titik berangkat kota asal.
class CurrentOriginController {
  CurrentOriginController(this._ref);

  final Ref _ref;

  /// Lokasi lebih jauh dari ini dari pusat kota dianggap di luar kota itu.
  static const cityRadiusKm = 60.0;

  /// [auto] = dipanggil saat aplikasi dibuka: arah perjalanan ikut kota tempat
  /// user berada. Dari pemilih titik berangkat, arah tidak diubah.
  Future<CurrentOriginResult> use({required bool auto}) async {
    final status = await _ref.read(myLocationProvider.notifier).locate();
    switch (status) {
      case LocationStatus.ready:
        break;
      case LocationStatus.denied:
        return CurrentOriginResult.denied;
      case LocationStatus.deniedForever:
        return CurrentOriginResult.deniedForever;
      case LocationStatus.serviceOff:
        return CurrentOriginResult.serviceOff;
      default:
        return CurrentOriginResult.failed;
    }
    final me = _ref.read(myLocationProvider);
    final lat = me.lat!;
    final lng = me.lng!;
    final city = nearestCity(lat, lng);
    final notifier = _ref.read(tripDraftProvider.notifier);
    if (city == null) return CurrentOriginResult.outsideCity;
    if (city != _ref.read(tripDraftProvider).originCity) {
      if (!auto) return CurrentOriginResult.outsideCity;
      notifier.setDirection(TripDirection.values.firstWhere((d) => d.originCity == city));
    }
    final address = await _ref.read(addressSearchProvider).reverse(lat, lng);
    notifier.setOrigin(OriginPoint(
      id: 'current',
      label: AppCopy.currentLocationLabel,
      address: address ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      kind: OriginKind.current,
      lat: lat,
      lng: lng,
    ));
    return CurrentOriginResult.ok;
  }

  /// Kota layanan terdekat dalam [cityRadiusKm], null kalau di luar semuanya.
  static String? nearestCity(double lat, double lng) {
    String? best;
    var bestKm = cityRadiusKm;
    for (final e in AppConfig.cityCenters.entries) {
      final km = haversineKm(lat, lng, e.value.lat, e.value.lng);
      if (km <= bestKm) {
        bestKm = km;
        best = e.key;
      }
    }
    return best;
  }
}

/// Sekali saat aplikasi dibuka: pakai titik tersimpan, lalu perbarui dari GPS
/// kalau titik itu memang "lokasi sekarang" (atau belum ada sama sekali).
/// Izin lokasi diminta di sini saat pertama kali.
final originBootstrapProvider = FutureProvider<void>((ref) async {
  final saved = await ref.read(tripDraftProvider.notifier).restoreOrigin();
  if (saved == null || saved.kind == OriginKind.current) {
    await ref.read(currentOriginProvider).use(auto: saved == null);
  }
});
