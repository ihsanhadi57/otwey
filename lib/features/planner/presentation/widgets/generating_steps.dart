import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Daftar langkah planner yang jalan satu per satu: menunggu, berputar, lalu centang.
/// Setelah semua selesai, mulai lagi selama halaman masih terbuka.
class GeneratingSteps extends StatefulWidget {
  const GeneratingSteps({required this.steps, super.key});

  final List<String> steps;

  @override
  State<GeneratingSteps> createState() => _GeneratingStepsState();
}

class _GeneratingStepsState extends State<GeneratingSteps> {
  Timer? _timer;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      setState(() => _active = (_active + 1) % (widget.steps.length + 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return OtwCard(
      style: OtwCardStyle.raised,
      radius: AppRadius.lg,
      child: Column(
        children: [
          for (var i = 0; i < widget.steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                SizedBox.square(
                  dimension: 28,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: _mark(i, c),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: (text.bodyLarge ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w600,
                      color: i <= _active ? c.ink : c.inkMuted.withValues(alpha: 0.7),
                    ),
                    child: Text(widget.steps[i]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mark(int i, AppColors c) {
    if (i < _active) {
      return OtwIconView(OtwIcon.done, key: const ValueKey('done'), variant: OtwIconVariant.fill, size: 28, color: c.accent, play: 1);
    }
    if (i == _active) {
      return Padding(
        key: const ValueKey('run'),
        padding: const EdgeInsets.all(3),
        child: CircularProgressIndicator(strokeWidth: 3, color: c.ink, backgroundColor: c.surface300),
      );
    }
    return Container(
      key: const ValueKey('wait'),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.line, width: 2)),
    );
  }
}
