import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/planner/data/itinerary_codec.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/saved_trips/data/local_saved_trip_repository.dart';
import 'package:otwey/features/saved_trips/domain/saved_trip.dart';
import 'package:shared_preferences/shared_preferences.dart';

Itinerary _sample() => Itinerary(
      originCity: 'Jakarta',
      destinationCity: 'Bandung',
      originLabel: 'Rumah',
      date: DateTime(2026, 11, 23),
      vibeLabel: 'Kulineran',
      budgetLabel: 'Sedang',
      freeMinutes: 60,
      latestReturn: 21 * 60,
      status: PlanStatus.tight,
      route: const [RoutePoint(lat: -6.9, lng: 107.6, kind: RoutePointKind.station, label: 'Bandung')],
      returnDeparture: 19 * 60,
      earlierReturnDeparture: 18 * 60,
      moreStopsAvailable: true,
      droppedPlaceNames: const ['Tempat X'],
      droppedPinNames: const ['Pin Y'],
      entries: [
        const PointEntry(time: 420, kind: PointKind.start, title: 'Rumah'),
        const LegEntry(
          id: 'l1',
          start: 420,
          destination: 'Stasiun',
          distanceKm: 5,
          ojol: LegOption(minutes: 20, costRupiah: 15000),
          transum: LegOption(minutes: 30, costRupiah: 5000),
          transumKind: TransitKind.rail,
          steps: [TransitStep(kind: TransitKind.walk, text: 'Jalan ke halte')],
          recommended: LegMode.ojol,
          fromLat: -6.2,
          fromLng: 106.8,
          toLat: -6.1,
          toLng: 106.7,
        ),
        const TrainEntry(departure: 480, arrival: 540, from: 'Halim', to: 'Padalarang', bufferMinutes: 20),
        const StopEntry(
          time: 600,
          number: 1,
          placeId: 'p1',
          title: 'Kopi',
          categoryCode: 'kopi',
          categoryLabel: 'Kopi',
          minutes: 45,
          optional: true,
          reason: 'Dekat stasiun',
          lat: -6.9,
          lng: 107.6,
          pinId: 'pin1',
        ),
        const FreeTimeEntry(time: 660, minutes: 30, beforeReturn: true),
        const LockedEntry(start: 780, end: 900, title: 'Meeting', purposeLabel: 'Kerja', lat: -6.89, lng: 107.61),
        const WalkEntry(minutes: 5),
        const PointEntry(time: 1200, kind: PointKind.arrivedHome, title: 'Rumah'),
      ],
    );

void main() {
  test('itinerary JSON round-trip mempertahankan semua jenis entry dan status', () {
    final it = _sample();
    final json = itineraryToJson(it);
    final back = itineraryFromJson(json);
    expect(itineraryToJson(back), json);
    expect(back.status, PlanStatus.tight);
    expect(back.droppedPinNames, ['Pin Y']);
    expect(back.legs.single.transum!.minutes, 30);
    expect(back.legs.single.steps.single.text, 'Jalan ke halte');
    expect(back.locked.single.title, 'Meeting');
    expect(back.freeBlocks.single.beforeReturn, isTrue);
  });

  test('pilihan moda JSON round-trip', () {
    const choices = {'l1': LegMode.transum};
    expect(legChoicesFromJson(legChoicesToJson(choices)), choices);
  });

  test('repository lokal menyimpan, memulihkan, mengganti moda, dan menghapus trip', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSavedTripRepository();
    expect(await repo.fetch(), isNull);

    final it = _sample();
    final id = await repo.save(SavedTrip(itinerary: it, choices: const {'l1': LegMode.transum}));
    final fetched = await repo.fetch();
    expect(fetched, isNotNull);
    expect(fetched!.id, id);
    expect(itineraryToJson(fetched.itinerary), itineraryToJson(it));
    expect(fetched.choices['l1'], LegMode.transum);

    await repo.updateChoices(id, const {'l1': LegMode.ojol});
    final updated = await repo.fetch();
    expect(updated!.choices['l1'], LegMode.ojol);

    await repo.clear();
    expect(await repo.fetch(), isNull);
  });
}