import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:otwey/core/widgets/fade_branch_container.dart';

/// Nilai opacity yang benar-benar dirender untuk cabang ke-[i].
double _fadeValue(WidgetTester tester, int i) {
  final fade = tester.widget<FadeTransition>(
    find
        .descendant(
          of: find.byType(AnimatedOpacity).at(i),
          matching: find.byType(FadeTransition),
        )
        .first,
  );
  return fade.opacity.value;
}

void main() {
  testWidgets('tab lama benar-benar memudar saat pindah ke indeks lebih rendah', (tester) async {
    var index = 0;
    late StateSetter setIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setIndex = setState;
            return FadeBranchContainer(
              index: index,
              children: const [
                Text('Beranda'),
                Text('Jelajah'),
                Text('Trip'),
                Text('Akun'),
              ],
            );
          },
        ),
      ),
    );

    // Beranda -> Akun (indeks naik).
    setIndex(() => index = 3);
    await tester.pumpAndSettle();
    expect(_fadeValue(tester, 3), 1);

    // Akun -> Beranda (indeks turun). Dulu tab Akun tertahan di opacity 1
    // dan menutupi Beranda.
    setIndex(() => index = 0);
    await tester.pumpAndSettle();
    expect(_fadeValue(tester, 3), 0);
    expect(_fadeValue(tester, 0), 1);
    expect(find.text('Beranda'), findsOneWidget);
  });
}
