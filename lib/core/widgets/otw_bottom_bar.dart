import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Area aksi menempel di bawah layar (tombol utama, info ringkas).
class OtwBottomBar extends StatelessWidget {
  const OtwBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface200,
        border: Border(top: BorderSide(color: c.line)),
        boxShadow: [
          BoxShadow(color: c.ink.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s3),
          child: child,
        ),
      ),
    );
  }
}
