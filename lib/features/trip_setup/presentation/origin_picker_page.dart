import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/otw_bottom_bar.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_header.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_press.dart';
import '../../../core/widgets/otw_skeleton.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../domain/origin_point.dart';
import 'current_origin.dart';
import 'origins_provider.dart';
import 'trip_draft_notifier.dart';
import 'widgets/origin_group.dart';
import 'widgets/origin_map_thumb.dart';

/// Pilih titik berangkat di kota asal. Stasiun kereta cepat diatur otomatis.
/// Pencarian alamat ada di peta penuh, bukan di halaman ini.
class OriginPickerPage extends ConsumerStatefulWidget {
  const OriginPickerPage({super.key});

  @override
  ConsumerState<OriginPickerPage> createState() => _OriginPickerPageState();
}

class _OriginPickerPageState extends ConsumerState<OriginPickerPage> {
  OriginPoint? _picked;
  bool _locating = false;

  void _choose(OriginPoint o) {
    ref.read(tripDraftProvider.notifier).setOrigin(o);
    context.pop();
  }

  Future<void> _pickOnMap() async {
    final o = await context.push<OriginPoint>(AppRoutes.originMap);
    if (o != null && mounted) _choose(o);
  }

  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    final result = await ref.read(currentOriginProvider).use(auto: false);
    if (!mounted) return;
    setState(() => _locating = false);
    final city = ref.read(tripDraftProvider).originCity;
    switch (result) {
      case CurrentOriginResult.ok:
        context.pop();
      case CurrentOriginResult.outsideCity:
        showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.outsideCity(city));
      case CurrentOriginResult.serviceOff:
        showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.locationOff);
      case CurrentOriginResult.denied:
        showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.locationDenied);
      case CurrentOriginResult.deniedForever:
        showOtwSnackBar(
          context,
          kind: OtwSnackKind.peringatan,
          message: AppCopy.locationDeniedForever,
          actionLabel: AppCopy.openSettings,
          onAction: () => ref.read(myLocationProvider.notifier).openSettings(LocationStatus.deniedForever),
        );
      case CurrentOriginResult.failed:
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.locationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(tripDraftProvider);
    final me = ref.watch(myLocationProvider);
    final asyncOrigins = ref.watch(originsProvider(draft.originCity));

    ref.listen(originsProvider(draft.originCity), (prev, next) {
      if (next is AsyncError) {
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
      }
    });

    final all = asyncOrigins.value ?? const <OriginPoint>[];
    final picked = _picked ?? draft.origin ?? (all.isEmpty ? null : all.first);
    final saved = all.where((o) => o.kind == OriginKind.home || o.kind == OriginKind.work).toList();
    final recent = all.where((o) => o.kind != OriginKind.home && o.kind != OriginKind.work).toList();
    final pickedCoords = picked != null && picked.lat != null && picked.lng != null
        ? (lat: picked.lat!, lng: picked.lng!)
        : null;
    // TODO(hadi): nama stasiun dari mst_station sesuai arah.
    final station = draft.originCity == 'Jakarta' ? 'Stasiun Halim' : 'Stasiun Padalarang';
    final etaMin = picked?.etaMinMinutes;
    final etaMax = picked?.etaMaxMinutes;

    return Scaffold(
      appBar: const OtwHeader(title: AppCopy.originTitle),
      body: asyncOrigins.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s6),
          children: const [
            OtwSkeleton(height: 168, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.s3),
            OtwSkeleton(height: 56, radius: 14),
            SizedBox(height: AppSpacing.s3),
            OtwSkeleton(height: 120, radius: 18),
          ],
        ),
        error: (error, _) => OtwErrorView(
          onRetry: () => ref.invalidate(originsProvider),
          body: AppCopy.noData,
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s6),
          children: [
            OriginMapThumb(
              city: draft.originCity,
              point: pickedCoords,
              me: me.hasFix ? (lat: me.lat!, lng: me.lng!) : null,
              onTap: _pickOnMap,
            ),
            const SizedBox(height: AppSpacing.s2),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _locating
                  ? SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.brand))
                  : OtwIconView(OtwIcon.locate, size: 24, color: c.brand),
              title: Text(AppCopy.useCurrentLocation, style: text.bodyLarge?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700)),
              subtitle: Text(_locating ? AppCopy.locating : AppCopy.useCurrentLocationHint,
                  style: text.bodySmall?.copyWith(color: c.inkMuted)),
              onTap: _locating ? null : _useCurrent,
            ),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
                child: Text(AppCopy.noData,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: c.inkMuted)),
              ),
            if (saved.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              OriginGroup(
                title: AppCopy.savedPlaces,
                origins: saved,
                selectedId: picked?.id,
                onSelect: (o) => setState(() => _picked = o),
              ),
            ],
            if (recent.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              OriginGroup(
                title: AppCopy.recentPlaces,
                origins: recent,
                selectedId: picked?.id,
                onSelect: (o) => setState(() => _picked = o),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: OtwBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OtwIconView(OtwIcon.route, size: 18, color: c.inkMuted),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: etaMin != null && etaMax != null
                      ? Text.rich(
                          TextSpan(children: [
                            TextSpan(text: AppCopy.toStationEta(station, '')),
                            TextSpan(
                              text: '${Clock.duration(etaMin)} sampai ${Clock.duration(etaMax)}',
                              style: AppTypography.timeSm(color: c.ink).copyWith(fontSize: 13),
                            ),
                          ]),
                          style: text.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13),
                        )
                      : Text(AppCopy.noData, style: text.bodySmall?.copyWith(color: c.inkMuted, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: picked == null
                  ? null
                  : () {
                      ref.read(tripDraftProvider.notifier).setOrigin(picked);
                      context.pop();
                    },
              child: const Text(AppCopy.useThisPoint),
            ),
          ],
        ),
      ),
    );
  }
}
