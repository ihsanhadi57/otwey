import '../../trip_setup/domain/trip_direction.dart';
import 'schedule.dart';

abstract interface class ScheduleRepository {
  Future<List<Station>> fetchStations();

  /// Perjalanan Whoosh aktif pada [direction] yang berlaku di [date].
  Future<List<WhooshTrip>> fetchWhooshTrips(TripDirection direction, DateTime date);

  /// Jadwal feeder aktif pada hari [date].
  Future<List<FeederDeparture>> fetchFeeders(DateTime date);
}
