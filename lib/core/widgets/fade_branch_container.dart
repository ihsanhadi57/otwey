import 'package:material_ui/material_ui.dart';

/// Wadah tab utama: semua cabang tetap hidup (state terjaga), perpindahan
/// tab berupa pudar silang pendek, bukan lompat.
class FadeBranchContainer extends StatelessWidget {
  const FadeBranchContainer({required this.index, required this.children, super.key});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              // TickerMode harus di dalam AnimatedOpacity. Kalau di luar,
              // ticker pudarnya ikut dimatikan sehingga tab lama tertahan di
              // opacity 1 dan menutupi tab yang baru dipilih.
              child: TickerMode(enabled: i == index, child: children[i]),
            ),
          ),
      ],
    );
  }
}
