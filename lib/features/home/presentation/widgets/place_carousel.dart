import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_section_title.dart';
import '../../../../core/widgets/otw_skeleton.dart';
import '../../../places/presentation/places_provider.dart';
import '../../../places/presentation/wishlist_notifier.dart';
import 'place_card.dart';
import '../../../../core/widgets/otw_press.dart';

/// Carousel tempat incaran di kota tujuan. Kartu terakhir terpotong supaya terasa bisa digeser.
class PlaceCarousel extends ConsumerWidget {
  const PlaceCarousel({required this.city, super.key});

  final String city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlaces = ref.watch(featuredPlacesProvider(city));
    final saved = ref.watch(wishlistProvider).value ?? const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: OtwSectionTitle(
            AppCopy.wishSectionTitle(city),
            subtitle: AppCopy.wishSectionSubtitle,
            trailing: OtwTextButton(
              onPressed: () => context.go(AppRoutes.explore),
              child: const Text(AppCopy.seeAll),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: 168,
          child: asyncPlaces.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => const OtwSkeleton(width: 220, height: 168, radius: 16),
            ),
            error: (error, _) => Center(
              child: OtwTextButton(
                onPressed: () => ref.invalidate(placesProvider),
                child: const Text(AppCopy.retry),
              ),
            ),
            data: (places) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              itemCount: places.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == places.length) {
                  return _SeeAllCard(
                    savedCount: saved.length,
                    onExplore: () => context.go(AppRoutes.explore),
                    onWishlist: () => context.push(AppRoutes.wishlist),
                  );
                }
                final p = places[i];
                return PlaceCard(
                  place: p,
                  saved: saved.contains(p.id),
                  onTap: () => context.push(AppRoutes.place(p.id)),
                  onToggleSaved: () => toggleWishlist(context, ref, p.id, withUndo: true),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu penutup carousel: ke Jelajah untuk semua tempat, atau ke wishlist.
class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({required this.savedCount, required this.onExplore, required this.onWishlist});

  final int savedCount;
  final VoidCallback onExplore;
  final VoidCallback onWishlist;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Material(
        color: c.brandTint,
        borderRadius: BorderRadius.circular(16),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onExplore,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OtwIconView(OtwIcon.explore, size: 28, color: c.brandStrong),
                const Spacer(),
                Text(AppCopy.exploreAll, style: text.titleSmall),
                const SizedBox(height: AppSpacing.s2),
                OtwInkWell(
                  onTap: onWishlist,
                  child: Row(
                    children: [
                      OtwIconView(OtwIcon.heart, variant: OtwIconVariant.fill, size: 14, color: c.brand),
                      const SizedBox(width: 4),
                      Text(AppCopy.wishlistCount(savedCount), style: text.labelMedium?.copyWith(color: c.brandStrong)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
