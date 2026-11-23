import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/location/my_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_locate_button.dart';
import '../../../core/widgets/otw_map.dart';
import '../../../core/widgets/otw_round_button.dart';
import '../../../core/widgets/otw_section_title.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../places/presentation/places_provider.dart';
import '../../planner/domain/itinerary.dart';
import '../../planner/domain/leg_mode.dart';
import '../../planner/presentation/itinerary_provider.dart';
import '../../planner/presentation/leg_choice_notifier.dart';
import '../../planner/presentation/widgets/result_map.dart';
import '../../planner/presentation/widgets/timeline_view.dart';
import '../../saved_trips/presentation/saved_trip_notifier.dart';
import '../domain/live_steps.dart';
import 'widgets/live_step_card.dart';
import '../../../core/widgets/otw_press.dart';

/// Mode jalan: peta penuh dengan posisi user, lembar berisi langkah aktif dan
/// rencana lengkap. Di hari H langkah mengikuti jam (bisa dimajukan dengan
/// "Udah sampai"). Sebelum hari H hanya pratinjau, dengan opsi simulasi.
class LiveTripPage extends ConsumerStatefulWidget {
  const LiveTripPage({super.key});

  @override
  ConsumerState<LiveTripPage> createState() => _LiveTripPageState();
}

class _LiveTripPageState extends ConsumerState<LiveTripPage> {
  /// Langkah yang sudah dicentang manual ("Udah sampai") atau dalam simulasi.
  int _manual = 0;
  bool _simulate = false;
  OtwMapFocus? _focus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedTripProvider).value;
    final Itinerary? planned = ref.watch(itineraryProvider).value;
    final itinerary = saved?.itinerary ?? planned;
    if (itinerary == null) {
      return Scaffold(
        backgroundColor: c.surface100,
        body: Center(child: Text(AppCopy.generating, style: text.bodyLarge)),
      );
    }
    final draftChoices = ref.watch(legChoiceProvider);
    LegMode modeOf(LegEntry l) =>
        saved != null ? saved.modeOf(l) : l.effective(draftChoices[l.id] ?? l.recommended);
    Future<void> choose(String id, LegMode m) async {
      if (saved == null) {
        ref.read(legChoiceProvider.notifier).choose(id, m);
        return;
      }
      try {
        if (!await ref.read(savedTripProvider.notifier).choose(id, m)) {
          if (!context.mounted) return;
          showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.modeDoesNotFit);
        }
      } catch (_) {
        if (!context.mounted) return;
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
      }
    }

    final now = DateTime.now();
    final days = daysUntil(itinerary.date, now);
    final active = days == 0 || _simulate;
    final steps = liveSteps(itinerary);
    final byClock = days == 0 ? currentStepAt(steps, now.hour * 60 + now.minute) : 0;
    final index = active ? (_simulate ? _manual : (byClock > _manual ? byClock : _manual)).clamp(0, steps.length) : -1;
    final current = index >= 0 && index < steps.length ? steps[index] : null;
    final next = index >= 0 && index + 1 < steps.length ? steps[index + 1] : null;

    final position = ref.watch(myPositionStreamProvider).value;
    final fix = ref.watch(myLocationProvider);
    final me = position?.hasFix == true
        ? (lat: position!.lat!, lng: position.lng!)
        : fix.hasFix
            ? (lat: fix.lat!, lng: fix.lng!)
            : null;
    final top = MediaQuery.paddingOf(context).top;
    final height = MediaQuery.sizeOf(context).height;

    void advance() {
      setState(() {
        _manual = index + 1;
        final target = _manual < steps.length ? steps[_manual] : null;
        if (target != null && target.hasPoint) _focus = OtwMapFocus(target.lat!, target.lng!);
      });
    }

    Future<void> directions(LiveStep step) async {
      final mode = step.leg == null
          ? DirectionsMode.walking
          : modeOf(step.leg!) == LegMode.transum
              ? DirectionsMode.transit
              : DirectionsMode.twoWheeler;
      final place = step.placeId == null ? null : ref.read(placeByIdProvider(step.placeId!)).value;
      final ok = await openDirections(step.lat!, step.lng!,
          mode: mode, label: place?.name ?? step.title, placeId: place?.googlePlaceId);
      if (!ok && context.mounted) {
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.openMapsFailed);
      }
    }

    return Scaffold(
      backgroundColor: c.surface100,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: height * 0.32,
            child: OtwMap(
              points: ResultMap.pointsOf(itinerary),
              showRoute: true,
              me: me,
              focus: _focus,
              fitPadding: const EdgeInsets.fromLTRB(48, 120, 48, 48),
              attributionInset: const EdgeInsets.only(bottom: 24),
            ),
          ),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: top + AppSpacing.s3,
            child: Row(
              children: [
                OtwRoundButton(icon: OtwIcon.back, tooltip: AppCopy.back, onPressed: () => context.pop()),
                const Spacer(),
                _HomeChip(time: Clock.format(itinerary.homeArrival)),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.screen,
            top: top + 72,
            child: OtwLocateButton(
              size: 48,
              onLocated: (lat, lng) => setState(() => _focus = OtwMapFocus(lat, lng)),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.34,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.34, 0.55, 0.88],
            builder: (context, scroll) => DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, -8))],
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s3, AppSpacing.screen, AppSpacing.s8),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  if (!active)
                    _NotTodayCard(
                      date: DateLabel.long(itinerary.date),
                      days: days,
                      onSimulate: days < 0
                          ? null
                          : () => setState(() {
                                _simulate = true;
                                _manual = 0;
                              }),
                    )
                  else if (current == null)
                    Text(AppCopy.liveDone, style: text.titleMedium)
                  else ...[
                    if (_simulate) ...[
                      Text(AppCopy.liveSimulating, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    LiveStepCard(
                      step: current,
                      label: AppCopy.liveNow,
                      mode: current.leg == null ? LegMode.ojol : modeOf(current.leg!),
                      onModeChanged: (m) => choose(current.leg!.id, m),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: OtwOutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            onPressed: advance,
                            icon: OtwIconView(OtwIcon.check, size: 18, color: c.ink),
                            label: const Text(AppCopy.arrived),
                          ),
                        ),
                        if (current.hasPoint) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OtwFilledButton.icon(
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              onPressed: () => directions(current),
                              icon: OtwIconView(OtwIcon.navigate,
                                  variant: OtwIconVariant.fill, size: 20, color: c.onBrand, knock: c.brand),
                              label: const Text(AppCopy.directions),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (next != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      _NextRow(step: next),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.s6),
                  const OtwSectionTitle(AppCopy.liveFullPlan),
                  const SizedBox(height: AppSpacing.s4),
                  TimelineView(
                    itinerary: itinerary,
                    doneSteps: active ? index : null,
                    choices: {for (final l in itinerary.legs) l.id: modeOf(l)},
                    onChoose: choose,
                    onOpenStop: (s) {
                      if (s.lat != null && s.lng != null) setState(() => _focus = OtwMapFocus(s.lat!, s.lng!));
                    },
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

class _HomeChip extends StatelessWidget {
  const _HomeChip({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface200,
      shape: const StadiumBorder(),
      elevation: 4,
      shadowColor: c.ink.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              AppCopy.onTimeHome(time),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotTodayCard extends StatelessWidget {
  const _NotTodayCard({required this.date, required this.days, required this.onSimulate});

  final String date;
  final int days;
  final VoidCallback? onSimulate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(color: c.sunTint, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OtwIconView(OtwIcon.calendar, size: 22, color: c.ink),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(days < 0 ? AppCopy.livePast : AppCopy.liveStartsIn(date, days), style: text.titleSmall),
              ),
            ],
          ),
          if (days >= 0) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(AppCopy.liveStartsHint, style: text.bodySmall?.copyWith(color: c.ink)),
            const SizedBox(height: AppSpacing.s3),
            OtwOutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: onSimulate,
              icon: OtwIconView(OtwIcon.navigate, size: 18, color: c.ink),
              label: const Text(AppCopy.liveSimulate),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({required this.step});

  final LiveStep step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final title = step.kind == LiveStepKind.free ? AppCopy.liveFreeTitle : step.title;
    return Row(
      children: [
        OtwIconView(LiveStepCard.iconOf(step.kind), size: 18, color: c.inkMuted),
        const SizedBox(width: AppSpacing.s2),
        Text('${AppCopy.liveNext} · ${Clock.format(step.time)}', style: text.labelMedium?.copyWith(color: c.inkMuted)),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelLarge),
        ),
      ],
    );
  }
}
