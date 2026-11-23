import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/trip_setup/domain/vibe_catalog.dart';

void main() {
  test('setiap vibes punya sub kategori', () {
    for (final v in VibeCatalog.vibes) {
      expect(VibeCatalog.subsOf(v.code), isNotEmpty, reason: v.code);
    }
  });

  test('default sub kategori diambil dari dua teratas', () {
    expect(VibeCatalog.defaultSubs('kulineran'), ['makanan_berat', 'jajanan']);
  });

  test('kode tak dikenal jatuh ke vibes pertama', () {
    expect(VibeCatalog.byCode('ngaco').code, 'kulineran');
  });
}
