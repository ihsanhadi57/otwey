import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Status pengambilan lokasi user.
enum LocationStatus { idle, loading, ready, denied, deniedForever, serviceOff, failed }

class MyLocation {
  const MyLocation({this.status = LocationStatus.idle, this.lat, this.lng});

  final LocationStatus status;
  final double? lat;
  final double? lng;

  bool get hasFix => lat != null && lng != null;
}

final myLocationProvider = NotifierProvider<MyLocationNotifier, MyLocation>(MyLocationNotifier.new);

/// Lokasi user sekali ambil. Izin diminta saat pertama dipakai: saat Beranda
/// mengisi titik berangkat dari lokasi sekarang, atau tombol "lokasi saya".
class MyLocationNotifier extends Notifier<MyLocation> {
  @override
  MyLocation build() => const MyLocation();

  /// Minta izin bila perlu lalu ambil posisi. Mengembalikan status akhirnya.
  Future<LocationStatus> locate() async {
    state = MyLocation(status: LocationStatus.loading, lat: state.lat, lng: state.lng);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _fail(LocationStatus.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return _fail(LocationStatus.deniedForever);
      if (permission == LocationPermission.denied) return _fail(LocationStatus.denied);

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) state = MyLocation(status: LocationStatus.loading, lat: last.latitude, lng: last.longitude);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      state = MyLocation(status: LocationStatus.ready, lat: pos.latitude, lng: pos.longitude);
      return LocationStatus.ready;
    } catch (_) {
      if (state.hasFix) {
        state = MyLocation(status: LocationStatus.ready, lat: state.lat, lng: state.lng);
        return LocationStatus.ready;
      }
      return _fail(LocationStatus.failed);
    }
  }

  /// Buka pengaturan aplikasi (izin ditolak permanen) atau lokasi (GPS mati).
  Future<void> openSettings(LocationStatus status) async {
    if (status == LocationStatus.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  LocationStatus _fail(LocationStatus s) {
    state = MyLocation(status: s, lat: state.lat, lng: state.lng);
    return s;
  }
}

/// Posisi terus menerus untuk mode jalan. Hanya aktif selama halaman memakainya.
final myPositionStreamProvider = StreamProvider.autoDispose<MyLocation>((ref) async* {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
  ).map((p) => MyLocation(status: LocationStatus.ready, lat: p.latitude, lng: p.longitude));
});
