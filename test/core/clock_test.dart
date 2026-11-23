import 'package:otwey/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse dan format jam', () {
    expect(Clock.parseDbTime('06:25:00'), 385);
    expect(Clock.parseDbTime('18:25'), 1105);
    expect(Clock.format(565), '09.25');
    expect(Clock.toDbTime(385), '06:25:00');
  });

  test('format durasi', () {
    expect(Clock.duration(45), '45 mnt');
    expect(Clock.duration(120), '2 j');
    expect(Clock.duration(130), '2 j 10 mnt');
  });
}
