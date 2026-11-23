import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:flutter_test/flutter_test.dart';

PlanPin _pin(String id, {int? start, int? end, int? duration}) => PlanPin(
      id: id,
      name: id,
      lat: 0,
      lng: 0,
      purpose: PinPurpose.main,
      priority: PinPriority.penting,
      fixedStart: start,
      fixedEnd: end,
      durationMinutes: duration,
    );

void main() {
  test('prioritas default: jam tetap + kerjaan = wajib', () {
    expect(
      PlanPin.defaultPriority(purpose: PinPurpose.kerja, isFixedTime: true),
      PinPriority.wajib,
    );
    expect(
      PlanPin.defaultPriority(purpose: PinPurpose.main, isFixedTime: true),
      PinPriority.penting,
    );
  });

  test('urutan prioritas', () {
    final sorted = [...PinPriority.values]..sort((a, b) => b.rank.compareTo(a.rank));
    expect(sorted.last, PinPriority.wajib);
  });

  test('deteksi bentrok jam tetap', () {
    final meeting = _pin('meeting', start: 13 * 60, end: 15 * 60);
    final lunch = _pin('lunch', start: 14 * 60, end: 15 * 60);
    final coffee = _pin('coffee', start: 15 * 60, end: 16 * 60);
    final flexible = _pin('flex', duration: 45);

    expect(meeting.overlaps(lunch), isTrue);
    expect(meeting.overlaps(coffee), isFalse);
    expect(meeting.overlaps(flexible), isFalse);
  });
}
