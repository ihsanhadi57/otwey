import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/live/domain/live_steps.dart';
import 'package:otwey/features/planner/domain/greedy_day_planner.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/trip_setup/domain/travel_mode.dart';
import 'package:otwey/features/trip_setup/domain/trip_direction.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

import '../support/real_data.dart';

Itinerary _it() => Itinerary(
      originCity: 'Jakarta',
      destinationCity: 'Bandung',
      originLabel: 'Rumah',
      date: DateTime(2026, 11, 21),
      vibeLabel: 'Kulineran',
      budgetLabel: 'Hemat',
      freeMinutes: 0,
      latestReturn: 21 * 60,
      entries: const [
        PointEntry(time: 7 * 60, kind: PointKind.start, title: 'Mulai di Stasiun Halim'),
        TrainEntry(departure: 7 * 60, arrival: 7 * 60 + 30, from: 'Halim', to: 'Padalarang'),
        TrainEntry(departure: 7 * 60 + 41, arrival: 7 * 60 + 59, from: 'Padalarang', to: 'Bandung', isFeeder: true),
        PointEntry(time: 7 * 60 + 59, kind: PointKind.arrive, title: 'Tiba di Stasiun Bandung'),
        WalkEntry(minutes: 8),
        StopEntry(
          time: 8 * 60 + 20,
          number: 1,
          placeId: 'braga',
          title: 'Jalan Braga',
          categoryCode: 'sejarah_budaya',
          categoryLabel: 'Sejarah',
          minutes: 45,
          lat: -6.91,
          lng: 107.6,
        ),
        PointEntry(time: 20 * 60, kind: PointKind.arrivedHome, title: 'Udah sampai'),
      ],
    );

void main() {
  test('Perpindahan menempel ke langkah sesudahnya', () {
    final steps = liveSteps(_it());
    expect(steps.map((s) => s.kind), [
      LiveStepKind.start,
      LiveStepKind.train,
      LiveStepKind.feeder,
      LiveStepKind.arrive,
      LiveStepKind.stop,
      LiveStepKind.home,
    ]);
    expect(steps[4].walkMinutes, 8);
    expect(steps[4].hasPoint, isTrue);
  });

  test('Langkah aktif = langkah pertama yang belum selesai', () {
    final steps = liveSteps(_it());
    expect(currentStepAt(steps, 6 * 60), 0);
    expect(currentStepAt(steps, 7 * 60 + 10), 1);
    expect(currentStepAt(steps, 8 * 60 + 30), 4);
    expect(currentStepAt(steps, 22 * 60), steps.length);
  });

  test('Hari trip dibanding hari ini', () {
    expect(daysUntil(DateTime(2026, 11, 21), DateTime(2026, 11, 20, 23, 59)), 1);
    expect(daysUntil(DateTime(2026, 11, 21), DateTime(2026, 11, 21, 6)), 0);
    expect(daysUntil(DateTime(2026, 11, 21), DateTime(2026, 11, 22)), -1);
  });

  test('simulasi hari H dengan data asli: langkah aktif selalu maju sampai selesai', () {
    final data = RealData.load();
    var simulated = 0;
    for (final dir in TripDirection.values) {
      for (final mode in TravelMode.values) {
        final draft = TripDraft(
          direction: dir,
          travelDate: DateTime(2026, 11, 23),
          earliestDeparture: 7 * 60,
          latestReturn: 21 * 60,
          tripTypeCode: 'kulineran',
          categoryCodes: const ['makanan_berat', 'jajanan', 'kopi_kafe'],
          travelMode: mode,
        );
        final it = const GreedyDayPlanner().build(data.input(draft)).itinerary!;
        final steps = liveSteps(it);
        expect(steps, isNotEmpty);
        var last = 0;
        // Jalan menit demi menit dari sebelum berangkat sampai lewat tengah malam.
        for (var now = steps.first.time - 30; now <= 24 * 60; now++) {
          final i = currentStepAt(steps, now);
          expect(i, greaterThanOrEqualTo(last), reason: '${dir.name} ${mode.name} mundur di menit $now');
          last = i;
        }
        expect(last, steps.length, reason: 'trip tidak selesai di akhir hari');
        // Setiap langkah dengan titik punya koordinat untuk petunjuk arah.
        for (final s in steps.where((s) => s.kind == LiveStepKind.stop)) {
          expect(s.hasPoint, isTrue, reason: s.title);
        }
        simulated++;
      }
    }
    expect(simulated, 6);
  });
}
