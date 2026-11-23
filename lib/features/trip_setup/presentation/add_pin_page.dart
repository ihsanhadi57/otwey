import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_locate_button.dart';
import '../../../core/widgets/otw_map.dart';
import '../../../core/widgets/otw_segmented.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../../core/widgets/otw_time_picker_sheet.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/places_provider.dart';
import '../data/address_search.dart';
import '../domain/plan_pin.dart';
import 'trip_draft_notifier.dart';
import 'widgets/address_results_panel.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/priority_selector.dart';
import 'widgets/purpose_grid.dart';
import 'widgets/time_field.dart';
import '../../../core/widgets/otw_press.dart';

/// Tambah tujuan pasti: cari lokasi atau ketuk peta, lalu keperluan, jam,
/// dan prioritas. Peta memenuhi layar di belakang lembar form.
class AddPinPage extends ConsumerStatefulWidget {
  const AddPinPage({super.key});

  @override
  ConsumerState<AddPinPage> createState() => _AddPinPageState();
}

class _AddPinPageState extends ConsumerState<AddPinPage> {
  final _query = TextEditingController();
  final _name = TextEditingController();
  final _queryFocus = FocusNode();
  PinPurpose _purpose = PinPurpose.kerja;
  bool _fixed = true;
  int _start = 13 * 60;
  int _end = 15 * 60;
  int _duration = 60;
  PinPriority _priority = PinPriority.wajib;
  String? _address;

  /// Titik tujuan dari hasil cari atau ketukan peta. Null = belum dipilih.
  ({double lat, double lng})? _point;
  OtwMapFocus? _focus;

  List<AddressResult> _results = const [];
  bool _loading = false;
  bool _error = false;
  bool _searched = false;

  /// Pencarian online otomatis setelah user berhenti mengetik.
  Timer? _searchDebounce;

  /// Nomor permintaan pencarian, supaya hasil lama tidak menimpa.
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _queryFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _query.dispose();
    _name.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  String get _city => ref.read(tripDraftProvider).destinationCity;

  void _onQueryChanged(String raw) {
    _searchDebounce?.cancel();
    _searchSeq++;
    final q = raw.trim();
    final places = ref.read(placesInCityProvider(_city)).value ?? const <Place>[];
    setState(() {
      _results = ref.read(addressSearchProvider).fromCatalog(q, places);
      _searched = false;
      _error = false;
      if (q.length < 3) _loading = false;
    });
    if (q.length < 3) return;
    _searchDebounce = Timer(const Duration(milliseconds: 400), _searchOnline);
  }

  Future<void> _searchOnline() async {
    final q = _query.text.trim();
    if (q.length < 3) return;
    final req = ++_searchSeq;
    final local = _results.where((r) => r.fromCatalog).toList();
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final online = await ref.read(addressSearchProvider).online(q, _city);
      if (!mounted || req != _searchSeq) return;
      setState(() {
        _results = [...local, ...online];
        _searched = true;
      });
    } catch (_) {
      if (mounted && req == _searchSeq) setState(() => _error = true);
    } finally {
      if (mounted && req == _searchSeq) setState(() => _loading = false);
    }
  }

  void _pick(AddressResult r) {
    _searchDebounce?.cancel();
    _searchSeq++;
    _queryFocus.unfocus();
    setState(() {
      _point = (lat: r.lat, lng: r.lng);
      _focus = OtwMapFocus(r.lat, r.lng, zoom: 17);
      _name.text = r.name;
      _address = r.address;
      _query.text = r.name;
      _results = const [];
      _searched = false;
      _loading = false;
    });
  }

  Future<void> _pickStart() async {
    final v = await showOtwTimePicker(
      context,
      title: AppCopy.pickStartTime,
      initialMinutes: _start,
      contextLabel: '${AppCopy.endTime} ${Clock.format(_end)}',
    );
    if (v != null) setState(() => _start = v);
  }

  Future<void> _pickEnd() async {
    final v = await showOtwTimePicker(
      context,
      title: AppCopy.pickEndTime,
      initialMinutes: _end,
      contextLabel: '${AppCopy.startTime} ${Clock.format(_start)}',
    );
    if (v != null) setState(() => _end = v);
  }

  void _submit() {
    final point = _point;
    if (point == null) {
      showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.pickPointFirst);
      return;
    }
    if (_fixed && _end <= _start) {
      showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.endAfterStart);
      return;
    }
    final name = _name.text.trim();
    final pin = PlanPin(
      id: 'pin_${DateTime.now().microsecondsSinceEpoch}',
      name: name.isEmpty ? AppCopy.purposeLainnya : name,
      address: _address,
      lat: point.lat,
      lng: point.lng,
      purpose: _purpose,
      priority: _priority,
      fixedStart: _fixed ? _start : null,
      fixedEnd: _fixed ? _end : null,
      durationMinutes: _fixed ? null : _duration,
    );
    final error = ref.read(tripDraftProvider.notifier).addPin(pin);
    if (error != null) {
      showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: error);
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final city = ref.watch(tripDraftProvider.select((d) => d.destinationCity));
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
              center: AppConfig.cityCenter(city),
              focus: _focus,
              me: me.hasFix ? (lat: me.lat!, lng: me.lng!) : null,
              attributionInset: EdgeInsets.only(bottom: media.size.height * 0.22),
              points: [
                if (point != null) OtwMapPoint(lat: point.lat, lng: point.lng, kind: OtwMarkerKind.place),
              ],
              onTap: (lat, lng) {
                _searchDebounce?.cancel();
                _searchSeq++;
                setState(() {
                  _queryFocus.unfocus();
                  _point = (lat: lat, lng: lng);
                  _address = null;
                  _results = const [];
                  _searched = false;
                  _error = false;
                  _loading = false;
                });
              },
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
                      _searchDebounce?.cancel();
                      _searchOnline();
                    },
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  if (showResults)
                    AddressResultsPanel(
                      results: _results,
                      loading: _loading,
                      error: _error,
                      searched: _searched,
                      onPick: _pick,
                    )
                  else
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface200.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
                          child: Text(AppCopy.mapTapToPin, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.22,
            maxChildSize: 0.86,
            snap: true,
            snapSizes: const [0.5],
            builder: (context, scroll) => DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, -8))],
              ),
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.s3,
                  AppSpacing.screen,
                  AppSpacing.s8 + media.viewInsets.bottom,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      OtwIconView(OtwIcon.pin, variant: OtwIconVariant.fill, size: 28, color: point == null ? c.inkMuted : c.brand),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _name,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                hintText: AppCopy.pinNameHint,
                                border: InputBorder.none,
                                hintStyle: text.titleMedium?.copyWith(color: c.inkMuted),
                              ),
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              point == null
                                  ? AppCopy.pickPointHint
                                  : (_address ?? '${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}'),
                              style: text.bodySmall?.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  PurposeGrid(
                    selected: _purpose,
                    onChanged: (p) => setState(() {
                      _purpose = p;
                      _priority = PlanPin.defaultPriority(purpose: p, isFixedTime: _fixed);
                    }),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  OtwSegmented<bool>(
                    selected: _fixed,
                    onChanged: (v) => setState(() => _fixed = v),
                    segments: const [
                      OtwSegment(value: true, label: AppCopy.fixedTime),
                      OtwSegment(value: false, label: AppCopy.flexibleTime),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  if (_fixed)
                    Row(
                      children: [
                        Expanded(child: TimeField(label: AppCopy.startTime, minutes: _start, onTap: _pickStart)),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(child: TimeField(label: AppCopy.endTime, minutes: _end, onTap: _pickEnd)),
                      ],
                    )
                  else
                    OtwSegmented<int>(
                      selected: _duration,
                      onChanged: (v) => setState(() => _duration = v),
                      segments: [
                        for (final m in const [30, 60, 90, 120]) OtwSegment(value: m, label: Clock.duration(m)),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.s4),
                  PrioritySelector(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
                  const SizedBox(height: AppSpacing.s6),
                  OtwFilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _submit,
                    child: const Text(AppCopy.addToPlan),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.screen,
            bottom: media.size.height * 0.5 + AppSpacing.s3,
            child: OtwLocateButton(
              size: 48,
              onLocated: (lat, lng) => setState(() => _focus = OtwMapFocus(lat, lng, zoom: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
