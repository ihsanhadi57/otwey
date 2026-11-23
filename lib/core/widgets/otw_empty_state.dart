import 'package:material_ui/material_ui.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'animated_oti.dart';
import 'otw_press.dart';

/// Keadaan kosong: Oti bernapas pelan, judul, penjelasan, satu tombol utama.
class OtwEmptyState extends StatelessWidget {
  const OtwEmptyState({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    this.mood = OtiMood.zzz,
    this.secondaryLabel,
    this.onSecondary,
    this.decoration,
    super.key,
  });

  final OtiMood mood;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Hiasan bergerak di atas Oti, misalnya [FloatingSymbols].
  final Widget? decoration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: c.sunTint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOti(mood: mood, motion: OtiMotion.breathe, size: 140),
                  if (decoration != null) Positioned.fill(child: decoration!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.s2),
            Text(body, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: c.inkMuted, fontSize: 14)),
            const SizedBox(height: AppSpacing.s6),
            OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: onCta,
              child: Text(ctaLabel),
            ),
            if (secondaryLabel != null)
              OtwTextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}
