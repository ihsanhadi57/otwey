import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_map.dart';
import '../../../../core/widgets/otw_snackbar.dart';
import '../../domain/place.dart';
import '../../../../core/widgets/otw_press.dart';

/// Lokasi tempat: peta yang bisa digeser, alamat yang bisa disalin, dan
/// tombol petunjuk arah ke aplikasi peta.
class PlaceLocationCard extends StatelessWidget {
  const PlaceLocationCard({required this.place, super.key});

  final Place place;

  Future<void> _directions(BuildContext context) async {
    final ok = await openDirections(place.lat, place.lng, label: place.name, placeId: place.googlePlaceId);
    if (!ok && context.mounted) {
      showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.openMapsFailed);
    }
  }

  Future<void> _copy(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (context.mounted) showOtwSnackBar(context, kind: OtwSnackKind.sukses, message: AppCopy.addressCopied);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final address = place.address?.isNotEmpty == true ? place.address! : (place.area ?? place.city);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(AppCopy.location, style: text.titleMedium)),
        const SizedBox(height: AppSpacing.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: OtwMap(
            height: 190,
            points: [OtwMapPoint(lat: place.lat, lng: place.lng, kind: OtwMarkerKind.place, label: place.name)],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Material(
          color: c.surface200,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: OtwInkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => _copy(context, address),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, AppSpacing.s3, AppSpacing.s3, AppSpacing.s3),
              child: Row(
                children: [
                  OtwIconView(OtwIcon.pin, size: 22, color: c.brand),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${place.area ?? place.city} · ${AppCopy.tapToCopy}',
                          style: text.bodySmall?.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        OtwFilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: c.brandTint,
            foregroundColor: c.brandStrong,
          ),
          onPressed: () => _directions(context),
          icon: OtwIconView(OtwIcon.navigate, variant: OtwIconVariant.fill, size: 18, color: c.brandStrong, knock: c.brandTint),
          label: const Text(AppCopy.directions),
        ),
      ],
    );
  }
}
