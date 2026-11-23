import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_oti.dart';

/// Oti melayang di lingkaran kuning dengan titik rute yang mengitari. Berulang.
class OrbitOti extends StatefulWidget {
  const OrbitOti({this.size = 240, super.key});

  final double size;

  @override
  State<OrbitOti> createState() => _OrbitOtiState();
}

class _OrbitOtiState extends State<OrbitOti> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _orbit.stop();
    } else if (!_orbit.isAnimating) {
      _orbit.repeat();
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.size;
    return SizedBox.square(
      dimension: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.sun,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 12))],
            ),
          ),
          RotationTransition(
            turns: _orbit,
            child: CustomPaint(size: Size.square(s), painter: _OrbitPainter(ink: c.ink, dot: c.brand)),
          ),
          AnimatedOti(mood: OtiMood.happy, motion: OtiMotion.bob, size: s * 0.66),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.ink, required this.dot});

  final Color ink;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 12;
    final dash = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const steps = 48;
    for (var i = 0; i < steps; i++) {
      final a = i / steps * 6.283185307179586;
      final p = center + Offset.fromDirection(a, r);
      canvas.drawCircle(p, 1.4, dash);
    }
    canvas.drawCircle(center + Offset(0, -r), 7, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.ink != ink || old.dot != dot;
}
