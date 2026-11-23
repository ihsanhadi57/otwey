import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/widgets/otw_icon_data.dart';

void main() {
  test('setiap ikon punya bentuk dan minimal satu lapisan', () {
    for (final icon in OtwIcon.values) {
      final spec = otwIconSpecs[icon];
      expect(spec, isNotNull, reason: '$icon belum punya bentuk');
      expect(spec!.layers, isNotEmpty, reason: '$icon kosong');
    }
  });

  test('mangkok punya 3 garis asap yang bergerak berurutan', () {
    final steam = otwIconSpecs[OtwIcon.bowl]!
        .layers
        .where((l) => l.motion == OtwLayerMotion.steam)
        .map((l) => l.delay)
        .toList();
    expect(steam, [0, 1, 2]);
  });
}
