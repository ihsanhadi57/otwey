import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/geo.dart';

void main() {
  test('parseGeoPoint membaca EWKB hex dari PostgREST', () {
    final p = parseGeoPoint('0101000020E6100000FA42C879FFE65A407B6F67BA32AB1BC0')!;
    expect(p.lng, closeTo(107.61, 0.05));
    expect(p.lat, closeTo(-6.92, 0.05));
  });

  test('parseGeoPoint membaca GeoJSON dan WKT', () {
    expect(parseGeoPoint({'type': 'Point', 'coordinates': [106.8, -6.2]})!.lat, -6.2);
    final w = parseGeoPoint('SRID=4326;POINT(106.88 -6.24)')!;
    expect(w.lng, 106.88);
    expect(w.lat, -6.24);
  });

  test('parseGeoPoint menolak nilai tidak dikenal', () {
    expect(parseGeoPoint('abc'), isNull);
    expect(parseGeoPoint(null), isNull);
  });
}
