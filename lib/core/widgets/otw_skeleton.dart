import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Kotak placeholder dengan kilau berjalan selama data dimuat.
class OtwSkeleton extends StatefulWidget {
  const OtwSkeleton({
    this.width,
    this.height = 14,
    this.radius = 6,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<OtwSkeleton> createState() => _OtwSkeletonState();
}

class _OtwSkeletonState extends State<OtwSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
    final c = context.colors;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final x = -1.0 + 2.0 * _controller.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - 1, 0),
                    end: Alignment(x + 1, 0),
                    colors: [c.surface300, c.surface200, c.surface300],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
