import '../../../core/data/seed_catalog.dart';
import '../../planner/data/seed_schedule_repository.dart';
import '../../planner/domain/schedule.dart';
import '../domain/origin_point.dart';
import '../domain/origin_repository.dart';

/// Mode demo offline: titik berangkat = stasiun di kota asal dari CSV seed.
/// Alamat rumah/kantor user belum ada datanya, tidak dikarang.
///
/// TODO(hadi): tambah alamat tersimpan lokal setelah ada penyimpanan perangkat.
class SeedOriginRepository implements OriginRepository {
  @override
  Future<List<OriginPoint>> fetchByCity(String city) async {
    final data = await SeedCatalog.load();
    return originsFrom(SeedScheduleRepository.stationsFrom(data), city);
  }

  static List<OriginPoint> originsFrom(List<Station> stations, String city) => [
        for (final s in stations)
          if (s.city == city)
            OriginPoint(
              id: 'station_${s.code}',
              label: s.name,
              address: s.city,
              kind: OriginKind.station,
              lat: s.lat,
              lng: s.lng,
            ),
      ];
}