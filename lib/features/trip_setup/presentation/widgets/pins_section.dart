import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_confirm_dialog.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/otw_map.dart';
import '../../../../core/widgets/otw_section_title.dart';
import '../../../places/presentation/wishlist_notifier.dart';
import '../../domain/plan_pin.dart';
import '../trip_draft_notifier.dart';
import 'pin_tile.dart';
import '../../../../core/widgets/otw_press.dart';

/// Bagian "Tujuan kamu": peta mini, daftar tujuan, tambah tujuan, ambil dari wishlist.
class PinsSection extends ConsumerWidget {
  const PinsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final draft = ref.watch(tripDraftProvider);
    final wishCount = ref.watch(wishlistProvider).value?.length ?? 0;

    Future<void> confirmRemove(PlanPin pin) async {
      final ok = await showOtwConfirmDialog(
        context,
        title: AppCopy.deletePinTitle(pin.name),
        body: AppCopy.deletePinBody,
        confirmLabel: AppCopy.deletePinConfirm,
        cancelLabel: AppCopy.deleteCancel,
        tone: OtwDialogTone.danger,
        mood: OtiMood.mepet,
      );
      if (ok) ref.read(tripDraftProvider.notifier).removePin(pin.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OtwSectionTitle(AppCopy.yourPins, subtitle: AppCopy.yourPinsHint, brand: true),
        const SizedBox(height: AppSpacing.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: OtwMap(
            height: 180,
            interactive: false,
            center: AppConfig.cityCenter(draft.destinationCity),
            fitPadding: const EdgeInsets.all(32),
            points: [
              for (final pin in draft.pins)
                OtwMapPoint(
                  lat: pin.lat,
                  lng: pin.lng,
                  kind: pin.priority == PinPriority.wajib ? OtwMarkerKind.locked : OtwMarkerKind.place,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        for (final pin in draft.pins) ...[
          PinTile(pin: pin, onRemove: () => confirmRemove(pin)),
          const SizedBox(height: AppSpacing.s3),
        ],
        OtwOutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: c.lineStrong, style: BorderStyle.solid),
            backgroundColor: Colors.transparent,
          ),
          onPressed: () => context.push(AppRoutes.addPin),
          icon: OtwIconView(OtwIcon.plus, size: 20, color: c.ink),
          label: const Text(AppCopy.addPin),
        ),
        OtwTextButton.icon(
          onPressed: () => context.push(AppRoutes.wishlist),
          icon: OtwIconView(OtwIcon.heart, variant: OtwIconVariant.fill, size: 16, color: c.brand, knock: c.surface100),
          label: Text(AppCopy.fromWishlist(wishCount, draft.destinationCity)),
        ),
      ],
    );
  }
}
