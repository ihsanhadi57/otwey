import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/otw_map.dart';
import '../data/address_search.dart';
import '../domain/origin_point.dart';
import 'trip_draft_notifier.dart';
import 'widgets/address_results_panel.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/origin_point_card.dart';

/// Pilih titik berangkat di peta: ketuk peta atau cari alamat. Nama jalan dicari
/// lewat reverse geocoding. Mengembalikan [OriginPoint] ke halaman sebelumnya.
class OriginMapPage extends ConsumerStatefulWidget {
  const OriginMapPage({super.key});

  @override
  ConsumerState<OriginMapPage> createState() => _OriginMapPageState();
}

class _OriginMapPageState extends ConsumerState<OriginMapPage> {
  final _query = TextEditingController();
  final _queryFocus = FocusNode();

  ({double lat, double lng})? _point;
  String? _name;
  String? _address;
  bool _resolving = false;
  OtwMapFocus? _focus;

  List<AddressResult> _results = const [];
  bool _loading = false;
  bool _error = false;
  bool _searched = false;

  /// Nomor permintaan reverse geocoding, supaya hasil lama tidak menimpa.
  int _req = 0;

  /// Pencarian online otomatis setelah user berhenti mengetik.
  Timer? _queryDebounce;

  /// Nomor permintaan pencarian, supaya hasil lama tidak menimpa.
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _queryFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  String get _city => ref.read(tripDraftProvider).originCity;

  void _onQueryChanged(String raw) {
    _queryDebounce?.cancel();
    _searchSeq++;
    final q = raw.trim();
    if (q.length < 3) {
      if (_results.isNotEmpty || _searched || _error || _loading) {
        setState(() {
          _results = const [];
          _searched = false;
          _error = false;
          _loading = false;
        });
      }
      return;
    }
    _queryDebounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search([String? raw]) async {
    final q = (raw ?? _query.text).trim();
    if (q.length < 3) return;
    final req = ++_searchSeq;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final found = await ref.read(addressSearchProvider).online(q, _city);
      if (mounted && req == _searchSeq) {
        setState(() {
          _results = found;
          _searched = true;
        });
      }
    } catch (_) {
      if (mounted && req == _searchSeq) setState(() => _error = true);
    } finally {
      if (mounted && req == _searchSeq) setState(() => _loading = false);
    }
  }

  void _pickResult(AddressResult r) {
    _queryDebounce?.cancel();
    _searchSeq++;
    _queryFocus.unfocus();
    setState(() {
      _point = (lat: r.lat, lng: r.lng);
      _name = r.name;
      _address = r.address;
      _focus = OtwMapFocus(r.lat, r.lng, zoom: 17);
      _results = const [];
      _searched = false;
      _loading = false;
    });
  }

  Future<void> _pickPoint(double lat, double lng) async {
    _queryDebounce?.cancel();
    _searchSeq++;
    _queryFocus.unfocus();
    final req = ++_req;
    setState(() {
      _point = (lat: lat, lng: lng);
      _name = null;
      _address = null;
      _resolving = true;
      _results = const [];
      _searched = false;
      _error = false;
      _loading = false;
    });
    final address = await ref.read(addressSearchProvider).reverse(lat, lng);
    if (!mounted || req != _req) return;
    setState(() {
      _address = address;
      _resolving = false;
    });
  }

  void _confirm() {
    final p = _point;
    if (p == null) return;
    final address = _address ?? '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}';
    context.pop(OriginPoint(
      id: 'map_${p.lat.toStringAsFixed(5)}_${p.lng.toStringAsFixed(5)}',
      label: _name ?? address.split(',').first.trim(),
      address: address,
      kind: OriginKind.other,
      lat: p.lat,
      lng: p.lng,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final city = ref.watch(tripDraftProvider.select((d) => d.originCity));
    final me = ref.watch(myLocationProvider);
    final media = MediaQuery.of(context);
    final point = _point;
    // Tombol cari di keyboard menutup keyboard (fokus hilang), jadi hasil
    // pencarian online tetap tampil sampai user memilih atau mengetuk peta.
    final showResults = _loading || _error || _searched || (_queryFocus.hasFocus && _results.isNotEmpty);

    return Scaffold(
      backgroundColor: c.surface300,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: OtwMap(
              refitOnChange: false,
              center: me.hasFix ? (lat: me.lat!, lng: me.lng!) : AppConfig.cityCenter(city),
              focus: _focus,
              me: me.hasFix ? (lat: me.lat!, lng: me.lng!) : null,
              attributionInset: EdgeInsets.only(bottom: media.size.height * 0.2),
              points: [
                if (point != null) OtwMapPoint(lat: point.lat, lng: point.lng, kind: OtwMarkerKind.place),
              ],
              onTap: _pickPoint,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.screen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MapSearchBar(
                    controller: _query,
                    focusNode: _queryFocus,
                    onChanged: _onQueryChanged,
                    onSubmit: () {
                      _queryDebounce?.cancel();
                      _search();
                    },
                    hint: AppCopy.originSearch,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  if (showResults)
                    AddressResultsPanel(
                      results: _results,
                      loading: _loading,
                      error: _error,
                      searched: _searched,
                      onPick: _pickResult,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            bottom: media.padding.bottom + AppSpacing.s4,
            child: OriginPointCard(
              name: _name,
              address: _address,
              hasPoint: point != null,
              resolving: _resolving,
              onConfirm: point == null ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}
