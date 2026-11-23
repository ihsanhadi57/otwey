import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/trip_setup/domain/origin_point.dart';
import 'package:otwey/features/trip_setup/presentation/current_origin.dart';

void main() {
  test('kota terdekat dari koordinat, null di luar layanan', () {
    expect(CurrentOriginController.nearestCity(-6.2265, 106.8584), 'Jakarta'); // Tebet
    expect(CurrentOriginController.nearestCity(-6.9175, 107.6191), 'Bandung');
    expect(CurrentOriginController.nearestCity(-7.7956, 110.3695), isNull); // Yogyakarta
  });

  test('titik berangkat tersimpan bolak balik lewat JSON', () {
    const o = OriginPoint(
      id: 'current',
      label: 'Lokasi sekarang',
      address: 'Jl. Tebet Raya, Tebet Barat, Tebet',
      kind: OriginKind.current,
      lat: -6.2265,
      lng: 106.8584,
    );
    final back = OriginPoint.fromJson(o.toJson())!;
    expect(back.kind, OriginKind.current);
    expect(back.lat, o.lat);
    expect(back.shortLabel, 'Lokasi sekarang · Tebet');
  });
}
