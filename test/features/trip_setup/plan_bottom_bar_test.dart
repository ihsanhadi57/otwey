import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:otwey/core/theme/app_theme.dart';
import 'package:otwey/features/trip_setup/presentation/widgets/plan_bottom_bar.dart';

Widget _app({required int? freeMinutes}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    bottomNavigationBar: PlanBottomBar(freeMinutes: freeMinutes, onGenerate: () {}),
  ),
);

void main() {
  testWidgets('selama itinerary dihitung, tombol Gas ditahan dan angka diganti spinner', (tester) async {
    await tester.pumpWidget(_app(freeMinutes: null));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('±'), findsNothing);
  });

  testWidgets('setelah siap, tombol Gas aktif dan waktu luang tampil', (tester) async {
    await tester.pumpWidget(_app(freeMinutes: 300));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('± 5 j'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}