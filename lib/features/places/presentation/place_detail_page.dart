import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_round_button.dart';
import '../../trip_setup/domain/vibe_catalog.dart';
import 'places_provider.dart';
import 'wishlist_notifier.dart';
import 'widgets/place_about_section.dart';
import 'widgets/place_detail_bar.dart';
import 'widgets/place_info_list.dart';
import 'widgets/place_location_card.dart';
import 'widgets/place_photo_header.dart';
import 'widgets/place_title_block.dart';
import 'widgets/places_loading_view.dart';

/// Detail tempat untuk menjelajah (dari Beranda, Jelajah, Wishlist): menjelaskan
/// tempatnya. Untuk tempat yang sudah ada di itinerary, pakai StopDetailPage.
class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage({required this.placeId, super.key});

  final String placeId;

  /// Label sub kategori pertama tempat, dari katalog vibes.
  static String _categoryLabel(String code) {
    for (final v in VibeCatalog.vibes) {
      for (final s in VibeCatalog.subsOf(v.code)) {
        if (s.code == code) return s.label;
      }
    }
    return code;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlace = ref.watch(placeByIdProvider(placeId));
    if (asyncPlace is AsyncLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: PlacesLoadingView(rows: 3),
          ),
        ),
      );
    }
    if (asyncPlace is AsyncError) {
      return Scaffold(
        body: OtwErrorView(onRetry: () => ref.invalidate(placesProvider)),
      );
    }
    final place = asyncPlace.value;
    if (place == null) {
      return const Scaffold(body: Center(child: Text(AppCopy.noData)));
    }
    final saved = ref.watch(wishlistProvider).value?.contains(place.id) ?? false;
    final top = MediaQuery.paddingOf(context).top;

    void toggleSaved() => toggleWishlist(context, ref, place.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                PlacePhotoHeader(place: place),
                Positioned(
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                  top: top + AppSpacing.s3,
                  child: Row(
                    children: [
                      OtwRoundButton(icon: OtwIcon.back, tooltip: AppCopy.back, onPressed: () => context.pop()),
                      const Spacer(),
                      OtwRoundButton(icon: OtwIcon.share, tooltip: AppCopy.share, onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s4, AppSpacing.screen, AppSpacing.s8),
            sliver: SliverList.list(
              children: [
                PlaceTitleBlock(place: place, categoryLabel: _categoryLabel(place.categoryCodes.first)),
                const SizedBox(height: AppSpacing.s6),
                PlaceAboutSection(description: place.description),
                const SizedBox(height: AppSpacing.s6),
                PlaceInfoList(place: place, now: DateTime.now()),
                const SizedBox(height: AppSpacing.s6),
                PlaceLocationCard(place: place),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlaceDetailBar(saved: saved, onToggleSaved: toggleSaved),
    );
  }
}
