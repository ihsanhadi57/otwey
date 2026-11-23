import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_bottom_bar.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_header.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_segmented.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../trip_setup/domain/trip_direction.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../domain/place.dart';
import 'places_provider.dart';
import 'wishlist_notifier.dart';
import 'widgets/place_list_tile.dart';
import 'widgets/places_loading_view.dart';
import 'widgets/wishlist_empty_view.dart';
import '../../../core/widgets/otw_press.dart';

/// Wishlist: tempat incaran yang disimpan, dipisah per kota.
class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  String? _city;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final destination = ref.watch(tripDraftProvider.select((d) => d.destinationCity));
    final city = _city ?? destination;
    final asyncPlaces = ref.watch(placesProvider);
    final saved = ref.watch(wishlistProvider).value ?? const <String>{};
    final places = (asyncPlaces.value ?? const <Place>[])
        .where((p) => saved.contains(p.id))
        .toList();
    final cities = TripDirection.values.map((d) => d.destinationCity).toList()..sort();
    final shown = places.where((p) => p.city == city).toList();

    ref.listen(placesProvider, (prev, next) {
      if (next is AsyncError) {
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
      }
    });

    return Scaffold(
      appBar: const OtwHeader(title: AppCopy.wishlist, brandTitle: true),
      body: asyncPlaces.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.screen, AppSpacing.s6),
          children: const [PlacesLoadingView()],
        ),
        error: (error, _) => OtwErrorView(
          onRetry: () => ref.invalidate(placesProvider),
          body: AppCopy.noData,
        ),
        data: (_) => places.isEmpty
            ? const WishlistEmptyView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s6),
                children: [
                  Text(AppCopy.wishlistHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13, height: 19 / 13)),
                  const SizedBox(height: AppSpacing.s4),
                  OtwSegmented<String>(
                    selected: city,
                    onChanged: (v) => setState(() => _city = v),
                    segments: [
                      for (final ct in cities)
                        OtwSegment(value: ct, label: '$ct · ${places.where((p) => p.city == ct).length}'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  for (final p in shown) ...[
                    PlaceListTile(
                      place: p,
                      saved: true,
                      onTap: () => context.push(AppRoutes.place(p.id)),
                      onToggleSaved: () => toggleWishlist(context, ref, p.id, withUndo: true),
                      footer: OtwOutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), side: BorderSide(color: c.line)),
                        onPressed: () => context.push(AppRoutes.plan),
                        icon: OtwIconView(OtwIcon.plus, size: 18, color: c.ink),
                        label: const Text(AppCopy.addToPlanShort),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: places.isEmpty
          ? null
          : OtwBottomBar(
              child: OtwFilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => context.push(AppRoutes.plan),
                child: const Text(AppCopy.planFromWishlist),
              ),
            ),
    );
  }
}