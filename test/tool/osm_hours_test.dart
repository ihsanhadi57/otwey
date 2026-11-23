import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/osm_hours.dart';

void main() {
  test('24/7 jadi tiap hari 00:00-23:59', () {
    final h = parseOsmOpeningHours('24/7')!;
    expect(h.length, 7);
    expect(h.first, (day: 1, open: 0, close: 1439));
  });

  test('aturan hari dan beberapa rentang jam', () {
    final h = parseOsmOpeningHours('Mo-Fr 09:00-17:00; Sa,Su 10:00-14:00,16:00-20:00')!;
    expect(h.where((x) => x.day == 3).single, (day: 3, open: 540, close: 1020));
    expect(h.where((x) => x.day == 7).length, 2);
  });

  test('aturan belakangan menimpa, off menghapus hari', () {
    final h = parseOsmOpeningHours('Mo-Su 08:00-22:00; Mo off')!;
    expect(h.any((x) => x.day == 1), isFalse);
    expect(h.length, 6);
  });

  test('tanpa hari berarti tiap hari, lewat tengah malam dipotong', () {
    final h = parseOsmOpeningHours('18:00-02:00')!;
    expect(h.length, 7);
    expect(h.first.close, 1439);
  });

  test('pola yang tidak dikenal menghasilkan null, bukan tebakan', () {
    expect(parseOsmOpeningHours('sunrise-sunset'), isNull);
    expect(parseOsmOpeningHours('Mo-Fr 09:00-17:00; PH 10:00-12:00'), isNull);
    expect(parseOsmOpeningHours('Jan-Mar Mo 10:00-12:00'), isNull);
    expect(parseOsmOpeningHours(''), isNull);
  });
}
