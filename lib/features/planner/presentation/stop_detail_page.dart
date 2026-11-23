import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/otw_card.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../domain/itinerary.dart';
import 'result_edit_actions.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_map.dart';
import '../../../core/widgets/otw_round_button.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/places_provider.dart';
import '../../places/presentation/widgets/alternative_tile.dart';
import '../../places/presentation/widgets/google_place_info.dart';
import '../../places/presentation/widgets/place_facts_row.dart';
import '../../places/presentation/widgets/places_loading_view.dart';
import '../../places/presentation/widgets/why_this_card.dart';
import '../../places/presentation/wishlist_notifier.dart';
import 'itinerary_provider.dart';
import 'widgets/stop_number_badge.dart';
import '../../../core/widgets/otw_press.dart';

/// Detail tempat yang sudah masuk draft itinerary: slot jam, alasan dipilih,
/// tukar dengan alternatif. Untuk menjelajah tempat pakai PlaceDetailPage.
class StopDetailPage extends ConsumerStatefulWidget {
  const StopDetailPage({required this.placeId, super.key});

  final String placeId;

  @override
  ConsumerState<StopDetailPage> createState() => _StopDetailPageState();
}

class _StopDetailPageState extends ConsumerState<StopDetailPage> {
  int _heartPlay = 0;
  final _altKey = GlobalKey();

  Future<void> _directions(Place place) async {
    final ok = await openDirections(place.lat, place.lng, mode: DirectionsMode.twoWheeler, label: place.name, placeId: place.googlePlaceId);
    if (!ok && mounted) {
      showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.openMapsFailed);
    }
  }

  void _scrollToAlternatives() {
    final ctx = _altKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _swap(Itinerary itinerary, StopEntry stop, Place to) {
    ref.read(tripDraftProvider.notifier).swapRecommendation(itinerary, stop.placeId, to.id);
    showOtwSnackBar(context, kind: OtwSnackKind.sukses, message: AppCopy.swapped(stop.title, to.name));
    context.pop();
  }

  /// Tempat lain yang buka di jam slot ini, belum ada di rencana. Yang sekategori
  /// dan paling dekat dulu.
  static List<Place> _alternatives({
    required List<Place> all,
    required Place current,
    required StopEntry stop,
    required Itinerary itinerary,
    required List<String> excluded,
    required int weekday,
  }) {
    final used = {...itinerary.stops.map((s) => s.placeId), ...excluded};
    final primary = current.categoryCodes.isEmpty ? null : current.categoryCodes.first;
    double dist(Place p) => (p.lat - current.lat).abs() + (p.lng - current.lng).abs();
    final list = [
      for (final p in all)
        if (!used.contains(p.id) && p.isOpen(weekday, stop.time, stop.time + stop.minutes)) p,
    ]..sort((a, b) {
        final sa = a.categoryCodes.contains(primary) ? 0 : 1;
        final sb = b.categoryCodes.contains(primary) ? 0 : 1;
        return sa != sb ? sa - sb : dist(a).compareTo(dist(b));
      });
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final asyncPlace = ref.watch(placeByIdProvider(widget.placeId));
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
    final itinerary = ref.watch(itineraryProvider).value;
    final stop = itinerary?.stopByPlace(place.id);
    final saved = ref.watch(wishlistProvider).value?.contains(place.id) ?? false;
    final today = place.openingHours.where((h) => h.dayOfWeek == DateTime.now().weekday);
    final draft = ref.watch(tripDraftProvider);
    final canSwap = itinerary != null && stop != null && stop.pinId == null;
    final alternatives = !canSwap
        ? const <Place>[]
        : _alternatives(
            all: ref.watch(placesInCityProvider(place.city)).value ?? const <Place>[],
            current: place,
            stop: stop,
            itinerary: itinerary,
            excluded: draft.excludedPlaceIds,
            weekday: draft.travelDate.weekday,
          );
    final top = MediaQuery.paddingOf(context).top;

    void toggleSaved() {
      setState(() => _heartPlay++);
      toggleWishlist(context, ref, place.id);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                OtwMap(
                  height: 290,
                  points: [OtwMapPoint(lat: place.lat, lng: place.lng, kind: OtwMarkerKind.place)],
                ),
                Positioned(
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                  top: top + AppSpacing.s3,
                  child: Row(
                    children: [
                      OtwRoundButton(icon: OtwIcon.back, tooltip: AppCopy.back, onPressed: () => context.pop()),
                      const Spacer(),
                      OtwRoundButton(
                        icon: OtwIcon.heart,
                        variant: saved ? OtwIconVariant.fill : OtwIconVariant.line,
                        iconColor: saved ? c.brand : c.ink,
                        tooltip: saved ? AppCopy.removeFromWishlist : AppCopy.saveToWishlist,
                        play: _heartPlay,
                        onPressed: toggleSaved,
                      ),
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
                if (stop != null)
                  Row(
                    children: [
                      StopNumberBadge(stop.number, size: 22),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        '${AppCopy.stopOf(stop.number, itinerary?.stops.length ?? 0)} · '
                        '${Clock.format(stop.time)} – ${Clock.format(stop.time + stop.minutes)}',
                        style: text.bodySmall?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(place.name, style: text.titleLarge),
                Text(place.area ?? place.city, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                GooglePlaceInfo(place: place),
                const SizedBox(height: AppSpacing.s4),
                PlaceFactsRow(
                  facts: [
                    if (today.isNotEmpty)
                      PlaceFact(OtwIcon.calendar, AppCopy.openHours,
                          '${Clock.format(today.first.open)}–${Clock.format(today.first.close)}'),
                    PlaceFact(OtwIcon.clock, AppCopy.duration, Clock.duration(place.visitMinutes)),
                    PlaceFact(OtwIcon.walk, AppCopy.fromStation, Clock.duration(12)),
                  ],
                ),
                if (stop != null && itinerary != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  _StayCard(
                    stop: stop,
                    onEdit: () => ResultEditActions(context, ref, itinerary).editStay(stop),
                  ),
                ],
                if (stop?.reason != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  WhyThisCard(reason: stop!.reason!),
                ],
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    Expanded(
                      child: OtwOutlinedButton.icon(
                        onPressed: () => _directions(place),
                        icon: OtwIconView(OtwIcon.navigate, size: 18, color: c.ink),
                        label: const Text(AppCopy.navigate),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OtwFilledButton.icon(
                        onPressed: alternatives.isEmpty ? null : _scrollToAlternatives,
                        icon: OtwIconView(OtwIcon.swap, size: 18, color: c.onBrand),
                        label: const Text(AppCopy.swapPlace),
                      ),
                    ),
                  ],
                ),
                if (alternatives.isNotEmpty) ...[
                  SizedBox(key: _altKey, height: AppSpacing.s4),
                  Text(AppCopy.alternatives, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.s2),
                  for (final alt in alternatives) ...[
                    AlternativeTile(place: alt, onPick: () => _swap(itinerary!, stop!, alt)),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lama di tempat ini, bisa diubah dari sini (bukan dari kartu timeline).
class _StayCard extends StatelessWidget {
  const _StayCard({required this.stop, required this.onEdit});

  final StopEntry stop;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return OtwCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          OtwIconView(OtwIcon.clock, size: 22, color: c.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppCopy.stayHere, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                Text(
                  '${Clock.duration(stop.minutes)} · ${Clock.format(stop.time)}–${Clock.format(stop.time + stop.minutes)}',
                  style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          OtwOutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(72, 40), shape: const StadiumBorder()),
            onPressed: onEdit,
            child: const Text(AppCopy.changeDuration),
          ),
        ],
      ),
    );
  }
}
