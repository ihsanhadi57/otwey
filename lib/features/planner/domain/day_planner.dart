import '../../places/domain/place.dart';
import '../../trip_setup/domain/trip_draft.dart';
import 'access_route.dart';
import 'city_transit.dart';
import 'fare_rule.dart';
import 'plan_item.dart';
import 'planner_config.dart';
import 'schedule.dart';

/// Data yang dibutuhkan planner, sudah diambil dari repository.
class PlannerInput {
  const PlannerInput({
    required this.draft,
    required this.outboundTrips,
    required this.returnTrips,
    required this.feeders,
    required this.candidatePlaces,
    required this.travelMinutes,
    this.stations = const [],
    this.accessRoutes = const [],
    this.fareRules = const [],
    this.cityTransit,
    this.originTransit,
    this.config = const PlannerConfig(),
  });

  final TripDraft draft;
  final List<WhooshTrip> outboundTrips;
  final List<WhooshTrip> returnTrips;
  final List<FeederDeparture> feeders;
  final List<Place> candidatePlaces;
  final List<Station> stations;

  /// Koridor transum menuju/dari stasiun (`mst_access_route`).
  final List<AccessRoute> accessRoutes;

  /// Tarif dasar ojol/mobil (`mst_fare_rule`).
  final List<FareRule> fareRules;

  /// Rute transum offline antar tempat di kota tujuan (`tool/city_transit.dart`).
  /// Null atau kosong = hanya rute akses stasiun.
  final CityTransitIndex? cityTransit;

  /// Rute transum offline di kota asal, untuk perjalanan dari titik berangkat
  /// user ke stasiun dan sebaliknya.
  final CityTransitIndex? originTransit;

  /// Fungsi waktu tempuh dalam menit antar dua koordinat. Implementasinya membaca
  /// `cache_travel_time` atau estimasi jarak (PRD 8.4). Harus cepat dan sinkron.
  final int Function(double fromLat, double fromLng, double toLat, double toLng)
      travelMinutes;

  final PlannerConfig config;
}

/// Penyusun itinerary (PRD bagian 8). Implementasi harus deterministik dan diuji.
abstract interface class DayPlanner {
  PlanResult build(PlannerInput input);
}

/// Rencana tidak bisa dibuat, mis. tujuan Wajib tidak terkejar (PRD 8.3).
/// Presentation menampilkan dialog mepet dari [result].
class PlanConflictException implements Exception {
  const PlanConflictException(this.result);

  final PlanResult result;
}
