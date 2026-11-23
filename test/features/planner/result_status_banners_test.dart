import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:otwey/core/theme/app_theme.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/presentation/widgets/result_status_banners.dart';

Itinerary _itinerary({
  required PlanStatus status,
  required int latestReturn,
  required List<TimelineEntry> entries,
  List<String> droppedPinNames = const [],
}) => Itinerary(
  originCity: 'Jakarta',
  destinationCity: 'Bandung',
  originLabel: 'Rumah',
  date: DateTime(2026, 11, 23),
  vibeLabel: 'Kuliner',
  budgetLabel: 'Murah',
  entries: entries,
  freeMinutes: 0,
  latestReturn: latestReturn,
  status: status,
  droppedPinNames: droppedPinNames,
);

Widget _app(Itinerary itinerary) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: ResultStatusBanners(itinerary: itinerary)),
);

void main() {
  testWidgets('status mepet dan pin yang dilepas tampil sebagai peringatan', (tester) async {
    await tester.pumpWidget(
      _app(
        _itinerary(
          status: PlanStatus.tight,
          latestReturn: 19 * 60,
          entries: const [PointEntry(time: 18 * 60 + 43, kind: PointKind.arrivedHome, title: 'Sampai rumah')],
          droppedPinNames: const ['Farmhouse Lembang'],
        ),
      ),
    );

    expect(find.text('Mepet nih · 17 mnt lagi'), findsOneWidget);
    expect(find.text('Waktunya nggak cukup, jadi "Farmhouse Lembang" kita lepas dulu.'), findsOneWidget);
    expect(find.textContaining('Aman, masih sempat'), findsNothing);
  });

  testWidgets('status aman memakai banner aman', (tester) async {
    await tester.pumpWidget(
      _app(
        _itinerary(
          status: PlanStatus.safe,
          latestReturn: 21 * 60,
          entries: const [
            TrainEntry(departure: 18 * 60, arrival: 18 * 60 + 30, from: 'Padalarang', to: 'Halim', bufferMinutes: 22),
            PointEntry(time: 19 * 60 + 10, kind: PointKind.arrivedHome, title: 'Sampai rumah'),
          ],
        ),
      ),
    );

    expect(find.textContaining('Aman, masih sempat'), findsOneWidget);
    expect(find.textContaining('Mepet nih'), findsNothing);
  });
}
