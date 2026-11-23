import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_visual.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_locate_button.dart';
import '../../../core/widgets/otw_map.dart';
import '../../../core/widgets/otw_skeleton.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../trip_setup/domain/vibe_catalog.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../domain/place.dart';
import '../domain/place_filter.dart';
import 'places_provider.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/explore_search_bar.dart';
import 'widgets/place_filter_sheet.dart';
import 'widgets/place_list_tile.dart';
import 'widgets/places_loading_view.dart';
import 'wishlist_notifier.dart';
import '../../../core/widgets/otw_press.dart';

/// Tab Jelajah: peta tempat di kota tujuan dengan daftar di lembar bawah.
/// Cari, filter, dan pin di peta bisa diketuk untuk melihat tempatnya.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  static const _sheetMin = 0.18;
  static const _sheetMid = 0.42;

  final _search = TextEditingController();
  final _sheet = DraggableScrollableController();
  Timer? _searchDebounce;
  String _vibe = 'kulineran';
  PlaceFilter _filter = const PlaceFilter();
  String? _selectedId;
  OtwMapFocus? _focus;
  bool _mapReady = false;
  int _sheetZone = 1;

  Object? _filterKey;
  List<Place>? _filtered;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheetChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sheet.removeListener(_onSheetChanged);
    _search.dispose();
    _sheet.dispose();
    super.dispose();
  }

  /// Peta menutup sebagian layar saat sheet ditarik: kurangi penanda supaya
  /// paint tetap ringan. Zona hanya diperbarui saat melewati ambang, bukan
  /// setiap frame tarikan.
  void _onSheetChanged() {
    if (!_sheet.isAttached) return;
    final size = _sheet.size;
    final zone = size <= _sheetMin + 0.06 ? 0 : (size >= 0.7 ? 2 : 1);
    if (zone != _sheetZone) setState(() => _sheetZone = zone);
  }

  int? get _markerLimit => switch (_sheetZone) {
    0 => 12,
    1 => 32,
    _ => null,
  };

  Set<String> get _subs => VibeCatalog.subsOf(_vibe).map((s) => s.code).toSet();

  /// Hasil filter di-cache per kombinasi data, filter, wishlist, dan menit
  /// sekarang (filter "buka sekarang" ikut waktu). Dengan begitu rebuild
  /// karena peta/sheet tidak menghitung ulang seluruh daftar.
  List<Place> _apply(List<Place> all, PlaceFilter f, Set<String> saved) {
    final now = DateTime.now();
    final key = Object.hash(all, f, saved, _vibe, now.hour, now.minute);
    if (key == _filterKey) return _filtered!;
    final result = f.apply(all, categories: _subs, saved: saved, now: now);
    _filterKey = key;
    _filtered = result;
    return result;
  }

  void _select(Place p) {
    setState(() {
      _selectedId = p.id;
      _focus = OtwMapFocus(p.lat, p.lng, zoom: 16);
    });
    if (_sheet.isAttached) {
      _sheet.animateTo(
        _sheetMid,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onQueryChanged(String q) {
    _searchDebounce?.cancel();
    if (_filter.query == q) return;
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(query: q));
    });
  }

  Future<void> _openFilter(List<Place> all, Set<String> saved) async {
    _searchDebounce?.cancel();
    if (_search.text != _filter.query) {
      setState(() => _filter = _filter.copyWith(query: _search.text));
    }
    final next = await showPlaceFilterSheet(
      context,
      initial: _filter,
      countOf: (f) => _apply(all, f, saved).length,
    );
    if (next != null) setState(() => _filter = next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final city = ref.watch(tripDraftProvider.select((d) => d.destinationCity));
    final asyncPlaces = ref.watch(placesInCityProvider(city));
    final saved = ref.watch(wishlistProvider).value ?? const <String>{};
    final me = ref.watch(myLocationProvider);
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final height = media.size.height;
    final headerBottom =
        top + AppSpacing.s3 + ExploreSearchBar.height + 10 + 44;
    final sheetMax = ((height - headerBottom - AppSpacing.s3) / height).clamp(
      _sheetMid,
      0.92,
    );

    ref.listen(placesProvider, (prev, next) {
      if (next is AsyncError) {
        showOtwSnackBar(
          context,
          kind: OtwSnackKind.gagal,
          message: AppCopy.errorConnection,
        );
      }
    });

    final all = asyncPlaces.value ?? const <Place>[];
    final places = _apply(all, _filter, saved);
    Place? selected;
    for (final p in all) {
      if (p.id == _selectedId) selected = p;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _mapReady
                ? OtwMap(
                    center: AppConfig.cityCenter(city),
                    fitPadding: EdgeInsets.fromLTRB(
                      40,
                      headerBottom + 24,
                      40,
                      height * _sheetMid + 24,
                    ),
                    me: me.hasFix ? (lat: me.lat!, lng: me.lng!) : null,
                    focus: _focus,
                    selectedId: _selectedId,
                    maxMarkers: _markerLimit,
                    onPointTap: (p) {
                      for (final place in all) {
                        if (place.id == p.id) _select(place);
                      }
                    },
                    attributionInset: EdgeInsets.only(
                      bottom: height * _sheetMin,
                    ),
                    points: [
                      for (final p in places)
                        OtwMapPoint(
                          lat: p.lat,
                          lng: p.lng,
                          kind: OtwMarkerKind.place,
                          id: p.id,
                          label: p.id == _selectedId ? p.name : null,
                        ),
                    ],
                  )
                : const _MapSkeleton(),
          ),
          Positioned(
            top: top + AppSpacing.s3,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: ExploreSearchBar(
                    controller: _search,
                    hint: AppCopy.searchIn(city),
                    filterCount: _filter.activeCount,
                    onChanged: _onQueryChanged,
                    onFilter: () => _openFilter(all, saved),
                  ),
                ),
                const SizedBox(height: 10),
                CategoryFilterBar(
                  selected: _filter.searching ? '' : _vibe,
                  onChanged: (v) => setState(() {
                    _vibe = v;
                    _searchDebounce?.cancel();
                    _search.clear();
                    _filter = _filter.copyWith(query: '');
                  }),
                ),
              ],
            ),
          ),
          // Tombol lokasi menempel di atas lembar, hilang saat lembar dibuka penuh.
          AnimatedBuilder(
            animation: _sheet,
            builder: (context, child) {
              final extent = _sheet.isAttached ? _sheet.size : _sheetMid;
              return Positioned(
                right: AppSpacing.screen,
                bottom: extent * height + AppSpacing.s3,
                child: IgnorePointer(
                  ignoring: extent > 0.6,
                  child: AnimatedOpacity(
                    opacity: extent > 0.6 ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: child,
                  ),
                ),
              );
            },
            child: OtwLocateButton(
              onLocated: (lat, lng) =>
                  setState(() => _focus = OtwMapFocus(lat, lng, zoom: 15)),
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: _sheetMid,
            minChildSize: _sheetMin,
            maxChildSize: sheetMax,
            snap: true,
            snapSizes: [_sheetMid],
            builder: (context, scroll) => DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.ink.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.s3,
                      AppSpacing.screen,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: c.line,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s3),
                          if (selected != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppCopy.selectedOnMap,
                                    style: text.labelLarge?.copyWith(
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ),
                                OtwIconButton(
                                  tooltip: AppCopy.close,
                                  onPressed: () =>
                                      setState(() => _selectedId = null),
                                  icon: OtwIconView(
                                    OtwIcon.close,
                                    size: 18,
                                    color: c.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                            PlaceListTile(
                              place: selected,
                              saved: saved.contains(selected.id),
                              onTap: () =>
                                  context.push(AppRoutes.place(selected!.id)),
                              onToggleSaved: () =>
                                  toggleWishlist(context, ref, selected!.id),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                          ],
                          Row(
                            children: [
                              if (!_filter.searching) ...[
                                OtwIconView(
                                  CategoryVisual.icon(_vibe),
                                  size: 22,
                                  color: CategoryVisual.tint(c, _vibe),
                                ),
                                const SizedBox(width: AppSpacing.s2),
                              ],
                              Expanded(
                                child: Text(
                                  _filter.searching
                                      ? AppCopy.searchResult(
                                          _filter.query.trim(),
                                        )
                                      : AppCopy.nearby(
                                          VibeCatalog.byCode(_vibe).label,
                                          city,
                                        ),
                                  style: text.titleMedium,
                                ),
                              ),
                              if (asyncPlaces is AsyncData)
                                Text(
                                  AppCopy.placeCount(places.length),
                                  style: text.bodySmall?.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s3),
                        ],
                      ),
                    ),
                  ),
                  ...asyncPlaces.when<List<Widget>>(
                    loading: () => const [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: PlacesLoadingView(),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: OtwErrorView(
                            onRetry: () => ref.invalidate(placesProvider),
                            body: AppCopy.noData,
                          ),
                        ),
                      ),
                    ],
                    data: (_) {
                      final listed = [
                        for (final p in places)
                          if (p.id != _selectedId) p,
                      ];
                      if (listed.isEmpty) {
                        return [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screen,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.s6,
                                ),
                                child: Text(
                                  AppCopy.noResult,
                                  textAlign: TextAlign.center,
                                  style: text.bodyMedium?.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ];
                      }
                      return [
                        _FadeSliver(
                          swapKey: _filter.searching ? 'search' : _vibe,
                          sliver: SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screen,
                            ),
                            sliver: SliverList.builder(
                              itemCount: listed.length,
                              itemBuilder: (context, i) {
                                final p = listed[i];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.s3,
                                  ),
                                  child: PlaceListTile(
                                    place: p,
                                    saved: saved.contains(p.id),
                                    onTap: () =>
                                        context.push(AppRoutes.place(p.id)),
                                    onToggleSaved: () =>
                                        toggleWishlist(context, ref, p.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.s6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliver yang memudar masuk saat [swapKey] berubah, pengganti [OtwSmoothSwap]
/// untuk daftar lazy (sliver tidak bisa dibungkus AnimatedSwitcher).
class _FadeSliver extends StatefulWidget {
  const _FadeSliver({required this.swapKey, required this.sliver});

  final Object swapKey;
  final Widget sliver;

  @override
  State<_FadeSliver> createState() => _FadeSliverState();
}

class _FadeSliverState extends State<_FadeSliver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(_FadeSliver old) {
    super.didUpdateWidget(old);
    if (old.swapKey != widget.swapKey) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SliverFadeTransition(opacity: _opacity, sliver: widget.sliver);
}

/// Placeholder peta sebelum FlutterMap dibuat, supaya perpindahan tab tidak
/// tertahan membangun tile dan marker di frame pertama.
class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => OtwSkeleton(
      width: box.maxWidth,
      height: box.maxHeight,
      radius: 0,
    ),
  );
}
