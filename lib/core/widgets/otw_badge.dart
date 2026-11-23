import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Nada badge.
enum OtwBadgeTone { wajib, soft, success }

/// Label kecil status, misalnya Wajib, Kalau sempat, Selesai.
class OtwBadge extends StatelessWidget {
  const OtwBadge(this.label, {this.tone = OtwBadgeTone.soft, super.key});

  final String label;
  final OtwBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (tone) {
      OtwBadgeTone.wajib => (c.brand, c.onBrand, null),
      OtwBadgeTone.soft => (Colors.transparent, c.inkMuted, c.lineStrong),
      OtwBadgeTone.success => (c.accentTint, c.accent, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
