import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/brand.dart';

/// Penjelasan kenapa planner memilih tempat ini, dengan Oti "sip".
class WhyThisCard extends StatelessWidget {
  const WhyThisCard({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s3),
      decoration: BoxDecoration(color: c.sunTint, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Oti(mood: OtiMood.sip, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: '${AppCopy.whyThis} ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: reason),
              ]),
              style: text.bodyMedium?.copyWith(fontSize: 13, height: 18 / 13),
            ),
          ),
        ],
      ),
    );
  }
}
