import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Cerita singkat tentang tempat.
class PlaceAboutSection extends StatelessWidget {
  const PlaceAboutSection({required this.description, super.key});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(AppCopy.aboutPlace, style: text.titleMedium)),
        const SizedBox(height: AppSpacing.s2),
        Text(
          description ?? AppCopy.noDescription,
          style: text.bodyLarge?.copyWith(color: description == null ? c.inkMuted : c.ink, height: 24 / 15),
        ),
      ],
    );
  }
}
