import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_switch_row.dart';
import '../../places/presentation/wishlist_notifier.dart';
import '../../trip_setup/domain/travel_mode.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import 'profile_provider.dart';
import 'widgets/profile_card.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_row.dart';

/// Tab Akun: profil, wishlist, preferensi trip, pengingat.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  // TODO(hadi): simpan preferensi pengingat ke profil.
  bool _leave = true;
  bool _tight = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider);
    final draft = ref.watch(tripDraftProvider);
    final wish = ref.watch(wishlistProvider).value?.length ?? 0;
    final mode = switch (draft.travelMode) {
      TravelMode.campur => AppCopy.travelCampur,
      TravelMode.ojol => AppCopy.travelOjol,
      TravelMode.transum => AppCopy.travelTransum,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.screen, AppSpacing.s8),
          children: [
            Text(AppCopy.accountTitle, style: text.titleLarge?.copyWith(fontSize: 26)),
            const SizedBox(height: AppSpacing.s4),
            ProfileCard(profile: profile, onEdit: () {}),
            const SizedBox(height: AppSpacing.s4),
            SettingsGroup(children: [
              SettingsRow(
                icon: OtwIcon.heart,
                iconVariant: OtwIconVariant.fill,
                iconColor: c.brand,
                label: AppCopy.wishlist,
                value: AppCopy.placesSaved(wish),
                onTap: () => context.push(AppRoutes.wishlist),
              ),
            ]),
            const SizedBox(height: AppSpacing.s6),
            SettingsGroup(title: AppCopy.tripPrefs, children: [
              SettingsRow(
                icon: OtwIcon.home,
                label: AppCopy.departFrom,
                value: draft.origin?.shortLabel,
                onTap: () => context.push(AppRoutes.origin),
              ),
              SettingsRow(icon: OtwIcon.route, label: AppCopy.travelBetween, value: mode, onTap: () => context.push(AppRoutes.plan)),
              SettingsRow(icon: OtwIcon.bowl, label: AppCopy.favoriteVibe, value: draft.vibe.label, onTap: () => context.push(AppRoutes.plan)),
            ]),
            const SizedBox(height: AppSpacing.s6),
            SettingsGroup(title: AppCopy.reminders, children: [
              OtwSwitchRow(icon: OtwIcon.bell, label: AppCopy.reminderLeave, value: _leave, boxed: false,
                  onChanged: (v) => setState(() => _leave = v)),
              OtwSwitchRow(icon: OtwIcon.clock, label: AppCopy.reminderTight, value: _tight, boxed: false,
                  onChanged: (v) => setState(() => _tight = v)),
            ]),
            const SizedBox(height: AppSpacing.s6),
            SettingsGroup(children: [
              SettingsRow(icon: OtwIcon.help, label: AppCopy.help, onTap: () {}),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(AppCopy.tagline, style: text.labelLarge?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500)),
                    ),
                    Text('v0.1.0', style: AppTypography.timeSm(color: c.inkMuted).copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
