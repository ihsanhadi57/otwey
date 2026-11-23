import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/profile.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kartu profil kuning di tab Akun.
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.profile, required this.onEdit, super.key});

  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(color: c.sun, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: c.ink,
            child: Text(
              profile.name.isEmpty ? '' : profile.name.substring(0, 1),
              style: TextStyle(fontFamily: AppFonts.brand, fontSize: 24, fontWeight: FontWeight.w700, color: c.sun),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: text.titleMedium?.copyWith(color: c.ink)),
                Text(AppCopy.accountStats(profile.tripCount, profile.visitedCount),
                    style: text.labelLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          OtwIconButton(
            tooltip: AppCopy.change,
            onPressed: onEdit,
            icon: OtwIconView(OtwIcon.edit, size: 20, color: c.ink),
          ),
        ],
      ),
    );
  }
}
