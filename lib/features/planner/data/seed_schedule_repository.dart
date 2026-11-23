import '../../../core/data/seed_catalog.dart';
import '../../../core/utils/seed_validate.dart';
import '../../trip_setup/domain/trip_direction.dart';
import '../domain/schedule.dart';
import '../domain/schedule_repository.dart';

/// Mode demo offline: jadwal dari CSV seed yang sama dengan importer Supabase.
class SeedScheduleRepository implements ScheduleRepository {
  @override
  Future<List<Station>> fetchStations() async =>
      stationsFrom(await SeedCatalog.load());

  @override
  Future<List<WhooshTrip>> fetchWhooshTrips(
    TripDirection direction,
    DateTime date,
  ) async {
    final data = await SeedCatalog.load();
    return tripsFrom(data, date: date)
        .where((t) => t.direction == direction)
        .toList();
  }

  @override
  Future<List<FeederDeparture>> fetchFeeders(DateTime date) async {
    final data = await SeedCatalog.load();
    return feedersFrom(data, tripsFrom(data, date: date), date: date);
  }

  static List<Station> stationsFrom(SeedData data) => [
        for (var i = 0; i < data.stations.length; i++)
          Station(
            id: i + 1,
            code: data.stations[i].code,
            name: data.stations[i].name,
            city: data.stations[i].city,
            lat: data.stations[i].lat,
            lng: data.stations[i].lng,
          ),
      ];

  /// Kereta per grup train_no + direction + valid_from. Kalau [date] diisi,
  /// hanya kereta yang masa berlakunya mencakup tanggal itu dan beroperasi
  /// di hari itu (`service_days`).
  static List<WhooshTrip> tripsFrom(SeedData data, {DateTime? date}) {
    final groups = <String, List<WhooshRow>>{};
    for (final r in data.whoosh) {
      groups
          .putIfAbsent('${r.trainNo}|${r.direction}|${r.validFrom}', () => [])
          .add(r);
    }
    final trips = <WhooshTrip>[];
    for (final g in groups.values) {
      g.sort((a, b) => a.seq.compareTo(b.seq));
      final first = g.first;
      if (date != null) {
        final from = DateTime.tryParse(first.validFrom);
        final to = DateTime.tryParse(first.validTo);
        final day = DateTime(date.year, date.month, date.day);
        if (from != null && day.isBefore(from)) continue;
        if (to != null && day.isAfter(to)) continue;
        if (!first.serviceDays.contains(date.weekday)) continue;
      }
      trips.add(WhooshTrip(
        id: trips.length + 1,
        trainNo: first.trainNo,
        direction: TripDirection.fromDb(first.direction),
        stops: [
          for (final r in g)
            WhooshStop(
              stationCode: r.stationCode,
              sequence: r.seq,
              arrival: r.arrive,
              departure: r.depart,
            ),
        ],
      ));
    }
    return trips;
  }

  /// Jadwal feeder. Kalau [date] diisi, hanya yang beroperasi di hari itu.
  static List<FeederDeparture> feedersFrom(
    SeedData data,
    List<WhooshTrip> trips, {
    DateTime? date,
  }) => [
        for (var i = 0; i < data.feeders.length; i++)
          if (date == null || data.feeders[i].serviceDays.contains(date.weekday))
            FeederDeparture(
              id: i + 1,
              routeName: data.feeders[i].routeName,
              mode: data.feeders[i].mode,
              originStationCode: data.feeders[i].fromStation,
              destinationStationCode: data.feeders[i].toStation,
              departure: data.feeders[i].depart,
              arrival: data.feeders[i].arrive,
              fare: data.feeders[i].fare,
              freeForWhoosh: data.feeders[i].freeForWhoosh,
              connectsTripId: _tripId(trips, data.feeders[i].connectsTrainNo),
            ),
      ];

  static int? _tripId(List<WhooshTrip> trips, String trainNo) {
    if (trainNo.isEmpty) return null;
    for (final t in trips) {
      if (t.trainNo == trainNo) return t.id;
    }
    return null;
  }
}