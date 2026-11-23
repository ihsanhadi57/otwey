import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../data/place_details_repository.dart';
import '../../domain/google_place_details.dart';
import '../../domain/place.dart';

/// Rating dan status buka langsung dari Google, dengan atribusi "Data Google".
/// Tidak tampil apa pun selama memuat, kalau gagal, atau kalau tempat belum
/// punya place_id / Supabase belum aktif.
class GooglePlaceInfo extends ConsumerWidget {
  const GooglePlaceInfo({required this.place, super.key});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = place.googlePlaceId;
    if (id == null || ref.watch(placeDetailsRepositoryProvider) == null) return const SizedBox.shrink();
    final d = ref.watch(googlePlaceDetailsProvider(id)).value;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topLeft,
      child: d == null || (d.rating == null && d.openNow == null && !d.isClosed)
          ? const SizedBox(width: double.infinity)
          : Padding(padding: const EdgeInsets.only(top: 8), child: _Row(d: d)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.d});

  final GooglePlaceDetails d;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final status = switch (d.status) {
      BusinessStatus.closedPermanently => (AppCopy.closedPermanently, c.danger),
      BusinessStatus.closedTemporarily => (AppCopy.closedTemporarily, c.danger),
      _ when d.openNow == true => (AppCopy.openNow, c.accent),
      _ when d.openNow == false => (AppCopy.closedNow, c.inkMuted),
      _ => null,
    };
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (d.rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OtwIconView(OtwIcon.star, variant: OtwIconVariant.fill, size: 16, color: c.sun),
              const SizedBox(width: 4),
              Text(d.rating!.toStringAsFixed(1).replaceAll('.', ','),
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (d.ratingCount != null) ...[
                const SizedBox(width: 4),
                Text(AppCopy.ratingCount(d.ratingCount!), style: text.bodySmall?.copyWith(color: c.inkMuted)),
              ],
            ],
          ),
        if (status != null)
          Text(status.$1, style: text.labelLarge?.copyWith(color: status.$2, fontWeight: FontWeight.w700)),
        Text(AppCopy.googleData, style: text.labelSmall?.copyWith(color: c.inkMuted)),
      ],
    );
  }
}
