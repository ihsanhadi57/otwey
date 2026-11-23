import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../assets/app_assets.dart';
import 'brand.dart';

/// Gerak berulang Oti.
enum OtiMotion {
  /// Melayang naik turun sambil miring. Untuk loading menyusun rute.
  bob,

  /// Bernapas pelan. Untuk empty state.
  breathe,

  /// Goyang kiri kanan seperti mengendus. Untuk loading daftar tempat.
  sniff,

  /// Bergoyang cemas. Untuk dialog peringatan.
  worry,
}

/// Oti yang bergerak berulang. Diam kalau user menyalakan "kurangi gerakan".
///
/// Catatan: untuk animasi Oti yang lebih kaya (kedip, lambaian), pindahkan ke Rive
/// sesuai docs/BRAND.md. Widget ini cukup untuk gerak tubuh sederhana.
class AnimatedOti extends StatefulWidget {
  const AnimatedOti({
    this.mood = OtiMood.happy,
    this.motion = OtiMotion.bob,
    this.size = 160,
    super.key,
  });

  final OtiMood mood;
  final OtiMotion motion;
  final double size;

  @override
  State<AnimatedOti> createState() => _AnimatedOtiState();
}

class _AnimatedOtiState extends State<AnimatedOti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period(widget.motion),
  );

  static Duration _period(OtiMotion motion) => switch (motion) {
        OtiMotion.bob => const Duration(milliseconds: 1600),
        OtiMotion.breathe => const Duration(milliseconds: 2600),
        OtiMotion.sniff => const Duration(milliseconds: 1800),
        OtiMotion.worry => const Duration(milliseconds: 1400),
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
      _controller.value = 0;
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
    final oti = Oti(mood: widget.mood, size: widget.size);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin(2 * math.pi * _controller.value);
        final unit = widget.size / 160;
        switch (widget.motion) {
          case OtiMotion.bob:
            return Transform.translate(
              offset: Offset(0, -5 * unit * (1 - math.cos(2 * math.pi * _controller.value))),
              child: Transform.rotate(angle: 3 * wave * math.pi / 180, child: child),
            );
          case OtiMotion.breathe:
            return Transform.scale(
              scale: 1 + 0.02 * (1 - math.cos(2 * math.pi * _controller.value)),
              alignment: Alignment.bottomCenter,
              child: child,
            );
          case OtiMotion.sniff:
            return Transform.translate(
              offset: Offset(6 * unit * wave, 0),
              child: Transform.rotate(
                angle: 6 * wave * math.pi / 180,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          case OtiMotion.worry:
            return Transform.rotate(
              angle: 4 * wave * math.pi / 180,
              alignment: const Alignment(0, 0.8),
              child: child,
            );
        }
      },
      child: oti,
    );
  }
}
