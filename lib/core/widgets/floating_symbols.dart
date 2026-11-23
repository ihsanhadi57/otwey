import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Tiga simbol kecil yang melayang naik lalu hilang, berulang.
/// Dipakai di empty state: huruf "z" untuk Oti tidur, hati untuk wishlist.
class FloatingSymbols extends StatefulWidget {
  const FloatingSymbols({
    required this.builder,
    this.origin = const Alignment(0.45, -0.3),
    this.drift = const Offset(18, -50),
    super.key,
  });

  /// Membuat simbol ke-i (0, 1, 2). Ukuran boleh berbeda.
  final Widget Function(int index) builder;
  final Alignment origin;
  final Offset drift;

  @override
  State<FloatingSymbols> createState() => _FloatingSymbolsState();
}

class _FloatingSymbolsState extends State<FloatingSymbols>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          children: [
            for (var i = 0; i < 3; i++) _symbol(i),
          ],
        ),
      ),
    );
  }

  Widget _symbol(int i) {
    final t = (_controller.value + i / 3) % 1.0;
    final opacity = t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
    final scale = 0.6 + 0.5 * t;
    final sway = math.sin(t * math.pi * 2) * 4;
    return Align(
      alignment: widget.origin,
      child: Transform.translate(
        offset: Offset(widget.drift.dx * t + sway, widget.drift.dy * t),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: widget.builder(i)),
        ),
      ),
    );
  }
}
