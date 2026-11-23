import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/transit_router.dart';

void main() {
  // Dua jalur bersilang di halte X. Titik A dekat halte a1, titik B dekat b2.
  const stops = [
    TransitStop('a1', 'A1', -6.200, 106.800),
    TransitStop('x', 'X', -6.200, 106.830),
    TransitStop('b2', 'B2', -6.230, 106.830),
  ];
  const bus = TransitLine(key: 'bus', name: 'Bus 1', short: '1', mode: RideMode.brt, fare: Fare(base: 3500), fareGroup: 'tj');
  const bus2 = TransitLine(key: 'bus2', name: 'Bus 2', short: '2', mode: RideMode.bus, fare: Fare(base: 3500), fareGroup: 'tj');
  final patterns = [
    TransitPattern(line: bus, stops: [0, 1], minutes: [0, 8], headway: 10),
    TransitPattern(line: bus2, stops: [1, 2], minutes: [0, 9], headway: 6),
  ];

  test('pindah jalur di halte sama, menit termasuk tunggu, tarif terintegrasi sekali', () {
    final router = TransitRouter(stops, patterns);
    final r = router.routeMany(
      (lat: -6.2005, lng: 106.8005, name: 'A'),
      [(lat: -6.2305, lng: 106.8305, name: 'B')],
    ).single!;
    expect(r.rides, 2);
    final rides = r.legs.where((l) => !l.isWalk).toList();
    expect(rides.first.line!.short, '1');
    expect(rides.last.line!.short, '2');
    expect(rides.first.wait, 5); // setengah headway 10
    expect(rides.last.wait, 3);
    expect(r.fare, 3500);
    expect(r.legs.first.isWalk, isTrue);
    expect(r.legs.last.toName, 'B');
    // 8 + 9 di kendaraan + 5 + 3 tunggu + jalan kaki di ujung.
    expect(r.minutes, greaterThan(25));
  });

  test('tidak ada rute kalau tujuan di luar jangkauan halte', () {
    final router = TransitRouter(stops, patterns);
    final r = router.routeMany((lat: -6.2005, lng: 106.8005, name: 'A'), [(lat: -6.5, lng: 107.0, name: 'Jauh')]);
    expect(r.single, isNull);
  });

  test('tarif rel per km dengan batas', () {
    const f = Fare(base: 5000, baseKm: 1, perKm: 700, max: 20000);
    expect(f.of(0.5), 5000);
    expect(f.of(11), 12000);
    expect(f.of(100), 20000);
  });
}
