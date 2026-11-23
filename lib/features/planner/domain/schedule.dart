import '../../trip_setup/domain/trip_direction.dart';

/// Stasiun dari `mst_station`.
class Station {
  const Station({
    required this.id,
    required this.code,
    required this.name,
    required this.city,
    this.lat,
    this.lng,
  });

  final int id;
  final String code;
  final String name;
  final String city;
  final double? lat;
  final double? lng;
}

/// Satu pemberhentian dari `mst_whoosh_trip_stop`. Jam dalam menit sejak tengah malam.
class WhooshStop {
  const WhooshStop({
    required this.stationCode,
    required this.sequence,
    this.arrival,
    this.departure,
  });

  final String stationCode;
  final int sequence;
  final int? arrival;
  final int? departure;
}

/// Satu perjalanan kereta dari `mst_whoosh_trip`.
class WhooshTrip {
  const WhooshTrip({
    required this.id,
    required this.direction,
    required this.stops,
    this.trainNo,
  });

  final int id;
  final String? trainNo;
  final TripDirection direction;
  final List<WhooshStop> stops;

  WhooshStop? stopAt(String stationCode) {
    for (final s in stops) {
      if (s.stationCode == stationCode) return s;
    }
    return null;
  }

  /// Jam berangkat dari [stationCode], null jika kereta tidak berangkat dari sana.
  int? departureFrom(String stationCode) => stopAt(stationCode)?.departure;

  /// Jam tiba di [stationCode], null jika kereta tidak berhenti di sana.
  int? arrivalAt(String stationCode) => stopAt(stationCode)?.arrival;
}

/// Jadwal feeder dari `mst_feeder_schedule` + `mst_feeder_route`.
class FeederDeparture {
  const FeederDeparture({
    required this.id,
    required this.routeName,
    required this.mode,
    required this.originStationCode,
    required this.destinationStationCode,
    required this.departure,
    required this.arrival,
    required this.fare,
    required this.freeForWhoosh,
    this.connectsTripId,
  });

  final int id;
  final String routeName;
  final String mode;
  final String originStationCode;
  final String destinationStationCode;
  final int departure;
  final int arrival;
  final int fare;
  final bool freeForWhoosh;
  final int? connectsTripId;
}
