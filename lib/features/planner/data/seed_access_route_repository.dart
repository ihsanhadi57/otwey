import '../../../core/data/seed_catalog.dart';
import '../../../core/utils/seed_validate.dart';
import '../domain/access_route.dart';
import '../domain/access_route_repository.dart';

/// Mode demo offline: rute akses dari CSV seed yang sama dengan importer.
class SeedAccessRouteRepository implements AccessRouteRepository {
  @override
  Future<List<AccessRoute>> fetchAll() async =>
      routesFrom(await SeedCatalog.load());

  static List<AccessRoute> routesFrom(SeedData data) {
    final groups = <String, List<AccessStepRow>>{};
    for (final s in data.accessSteps) {
      groups.putIfAbsent(s.routeKey, () => []).add(s);
    }
    return [
      for (final e in groups.entries)
        AccessRoute(
          code: e.key,
          stationCode: e.value.first.stationCode,
          direction: AccessDirection.fromDb(e.value.first.direction),
          name: e.value.first.routeName.isEmpty ? e.key : e.value.first.routeName,
          anchorLat: e.value.first.anchorLat,
          anchorLng: e.value.first.anchorLng,
          steps: [
            for (final s in e.value..sort((a, b) => a.seq.compareTo(b.seq)))
              AccessStep(
                seq: s.seq,
                mode: s.mode,
                minutes: s.minutes,
                fare: s.fare,
                service: s.service.isEmpty ? null : s.service,
                corridor: s.corridor.isEmpty ? null : s.corridor,
                fromStop: s.fromStop.isEmpty ? null : s.fromStop,
                toStop: s.toStop.isEmpty ? null : s.toStop,
                operatingHours: s.operatingHours.isEmpty ? null : s.operatingHours,
              ),
          ],
        ),
    ];
  }
}