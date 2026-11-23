import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_oti.dart';
import '../../../../core/widgets/otw_card.dart';
import '../../../../core/widgets/otw_skeleton.dart';

/// Loading daftar tempat: Oti mengendus plus kartu skeleton berkilau.
class PlacesLoadingView extends StatelessWidget {
  const PlacesLoadingView({this.rows = 4, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: AppCopy.loadingPlacesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s3),
            decoration: BoxDecoration(color: c.sunTint, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const AnimatedOti(mood: OtiMood.happy, motion: OtiMotion.sniff, size: 44),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppCopy.loadingPlacesTitle, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(AppCopy.loadingPlacesBody, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows; i++) ...[
            const SizedBox(height: AppSpacing.s3),
            OtwCard(
              child: Row(
                children: [
                  const OtwSkeleton(width: 28, height: 28, radius: 8),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(widthFactor: 0.7 - i * 0.05, child: const OtwSkeleton(height: 14)),
                        const SizedBox(height: AppSpacing.s2),
                        const FractionallySizedBox(widthFactor: 0.45, child: OtwSkeleton(height: 10)),
                      ],
                    ),
                  ),
                  const OtwSkeleton(width: 22, height: 22, radius: 99),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
