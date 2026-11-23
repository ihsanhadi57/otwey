import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// Nomor urut tempat, sama dengan nomor di peta.
class StopNumberBadge extends StatelessWidget {
  const StopNumberBadge(this.number, {this.size = 28, super.key});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: TextStyle(color: c.onBrand, fontWeight: FontWeight.w800, fontSize: size * 0.5),
      ),
    );
  }
}
