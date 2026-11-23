import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Header kuning beranda: logo, notifikasi, akun, sapaan, dan Oti.
/// Bagian bawah dibiarkan kosong 72 px untuk kartu pencarian yang menumpuk.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: c.sun,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen, MediaQuery.paddingOf(context).top + AppSpacing.s3, AppSpacing.screen, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OtweyLogo(height: 30),
              const Spacer(),
              OtwIconButton(
                tooltip: AppCopy.notifications,
                onPressed: () {},
                icon: OtwIconView(OtwIcon.bell, size: 26, color: c.ink),
              ),
              Semantics(
                button: true,
                label: AppCopy.navAccount,
                excludeSemantics: true,
                child: OtwInkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.go(AppRoutes.account),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: c.ink,
                    child: Text(
                      name.isEmpty ? '' : name.substring(0, 1),
                      style: text.titleMedium?.copyWith(fontFamily: AppFonts.brand, color: c.sun),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppCopy.greeting(name), style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.s1),
                      Text(AppCopy.homeTitle, style: text.titleLarge?.copyWith(fontSize: 26, height: 31 / 26)),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 40),
                child: const Oti(mood: OtiMood.happy, size: 104),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
