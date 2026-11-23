import 'package:otwey/features/planner/domain/schedule.dart';
import 'package:otwey/features/planner/domain/train_selector.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jadwal contoh: berangkat dari Halim, tiba Padalarang 35 menit kemudian.
/// Bukan jadwal resmi.
WhooshTrip _trip(int id, int depart) => WhooshTrip(
      id: id,
      direction: TripDirection.jakartaToBandung,
      stops: [
        WhooshStop(stationCode: 'HLM', sequence: 1, departure: depart),
        WhooshStop(stationCode: 'PDL', sequence: 2, arrival: depart + 35),
      ],
    );

void main() {
  const selector = TrainSelector();
  final trips = [
    _trip(1, 6 * 60),
    _trip(2, 6 * 60 + 25),
    _trip(3, 8 * 60),
    _trip(4, 8 * 60 + 25),
  ];

  test('kereta pergi paling awal menghormati buffer 30 menit', () {
    final t = selector.earliestOutbound(
      trips: trips,
      fromStation: 'HLM',
      toStation: 'PDL',
      readyAtStation: 6 * 60, // tiba di Halim 06.00
    );
    // 06.00 butuh tiba 05.30, 06.25 butuh tiba 05.55: dua duanya tidak terkejar.
    // Kereta pertama yang terkejar adalah 08.00.
    expect(t?.id, 3);
  });

  test('kereta pergi paling akhir yang tetap sampai sebelum meeting', () {
    final t = selector.latestOutboundArrivingBy(
      trips: trips,
      fromStation: 'HLM',
      toStation: 'PDL',
      readyAtStation: 5 * 60,
      mustArriveBy: 9 * 60, // harus keluar stasiun Padalarang jam 09.00
    );
    // 08.25 tiba 09.00 + 10 buffer = 09.10, telat. 08.00 tiba 08.35 + 10 = 08.45, aman.
    expect(t?.id, 3);
  });

  test('tidak ada kereta yang cocok mengembalikan null', () {
    final t = selector.earliestOutbound(
      trips: trips,
      fromStation: 'HLM',
      toStation: 'PDL',
      readyAtStation: 23 * 60,
    );
    expect(t, isNull);
  });
}
