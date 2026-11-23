import 'package:material_ui/material_ui.dart';

/// Ganti isi dengan mulus: tinggi menyesuaikan perlahan (kalau jumlah item
/// beda) dan isi baru memudar masuk. [swapKey] berubah = isi diganti.
class OtwSmoothSwap extends StatelessWidget {
  const OtwSmoothSwap({required this.swapKey, required this.child, super.key});

  final Object swapKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOut,
        layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey(swapKey), child: child),
      ),
    );
  }
}
