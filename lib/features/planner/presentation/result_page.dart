import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/otw_bottom_bar.dart';
import '../../../core/widgets/otw_empty_state.dart';
import '../../../core/widgets/otw_error_view.dart';
import '../../../core/widgets/otw_icon.dart';
import '../../../core/widgets/otw_round_button.dart';
import '../../../core/widgets/otw_section_title.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../saved_trips/presentation/saved_trip_notifier.dart';
import '../domain/day_planner.dart';
import '../domain/itinerary.dart';
import '../domain/leg_mode.dart';
import 'itinerary_provider.dart';
import 'leg_choice_notifier.dart';
import 'result_edit_actions.dart';
import 'widgets/result_map.dart';
import 'widgets/result_stats_row.dart';
import 'widgets/result_status_banners.dart';
import 'widgets/timeline_view.dart';
import '../../../core/widgets/otw_press.dart';

/// Hasil itinerary: peta rute di atas, lembar timeline di bawah.
///
/// [saved] = tampilkan trip yang sudah disimpan (baca saja, pilihan moda
/// tetap bisa diganti). Selain itu tampilkan draft yang sedang disusun.
class ResultPage extends ConsumerWidget {
  const ResultPage({this.saved = false, super.key});

  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    if (saved) {
      final asyncTrip = ref.watch(savedTripProvider);
      final trip = asyncTrip.value;
      if (asyncTrip.isLoading) {
        return Scaffold(
          backgroundColor: c.surface100,
          body: Center(child: Text(AppCopy.generating, style: text.bodyLarge)),
        );
      }
      if (asyncTrip.hasError) {
        return Scaffold(
          backgroundColor: c.surface100,
          body: OtwErrorView(
            onRetry: () => ref.invalidate(savedTripProvider),
            body: AppCopy.noData,
          ),
        );
      }
      if (trip == null) {
        return Scaffold(
          backgroundColor: c.surface100,
          body: OtwEmptyState(
            mood: OtiMood.sip,
            title: AppCopy.tripTitle,
            body: AppCopy.noSavedTrip,
            ctaLabel: AppCopy.newTrip,
            onCta: () => context.go(AppRoutes.home),
          ),
        );
      }
      return _ResultView(
        itinerary: trip.itinerary,
        choices: {for (final l in trip.itinerary.legs) l.id: trip.modeOf(l)},
        onChoose: (id, mode) async {
          try {
            if (!await ref.read(savedTripProvider.notifier).choose(id, mode)) {
              if (!context.mounted) return;
              showOtwSnackBar(context, kind: OtwSnackKind.peringatan, message: AppCopy.modeDoesNotFit);
            }
          } catch (_) {
            if (!context.mounted) return;
            showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
          }
        },
        edit: null,
        bottom: OtwFilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => context.push(AppRoutes.live),
          icon: OtwIconView(OtwIcon.navigate, variant: OtwIconVariant.fill, size: 20, color: c.onBrand, knock: c.brand),
          label: const Text(AppCopy.startTrip),
        ),
      );
    }

    final asyncItinerary = ref.watch(itineraryProvider);
    final choices = ref.watch(legChoiceProvider);
    final itinerary = asyncItinerary.value;
    if (itinerary == null) {
      if (asyncItinerary.error is PlanConflictException) {
        return Scaffold(
          backgroundColor: c.surface100,
          body: OtwEmptyState(
            mood: OtiMood.mepet,
            title: AppCopy.tightTitle,
            body: AppCopy.statusImpossible,
            ctaLabel: AppCopy.changeTrain,
            onCta: () => context.go(AppRoutes.plan),
            secondaryLabel: AppCopy.changeTime,
            onSecondary: () => context.go(AppRoutes.plan),
          ),
        );
      }
      if (asyncItinerary.isLoading) {
        return Scaffold(
          backgroundColor: c.surface100,
          body: Center(child: Text(AppCopy.generating, style: text.bodyLarge)),
        );
      }
      return Scaffold(
        backgroundColor: c.surface100,
        body: OtwErrorView(
          onRetry: () => ref.invalidate(itineraryProvider),
          body: AppCopy.noData,
        ),
      );
    }

    Future<void> save() async {
      try {
        await ref.read(savedTripProvider.notifier).save(itinerary, {
          for (final l in itinerary.legs) l.id: l.effective(choices[l.id] ?? l.recommended),
        });
        if (!context.mounted) return;
        showOtwSnackBar(context, kind: OtwSnackKind.sukses, message: AppCopy.savedToTrip);
        context.go(AppRoutes.trips);
      } catch (_) {
        if (!context.mounted) return;
        showOtwSnackBar(context, kind: OtwSnackKind.gagal, message: AppCopy.errorConnection);
      }
    }

    return _ResultView(
      itinerary: itinerary,
      choices: choices,
      onChoose: ref.read(legChoiceProvider.notifier).choose,
      edit: ResultEditActions(context, ref, itinerary),
      bottom: OtwFilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: save,
        child: const Text(AppCopy.savePlan),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.itinerary,
    required this.choices,
    required this.onChoose,
    required this.edit,
    required this.bottom,
  });

  final Itinerary itinerary;
  final Map<String, LegMode> choices;
  final void Function(String legId, LegMode mode) onChoose;

  /// Null untuk trip tersimpan (tidak bisa diedit di sini).
  final ResultEditActions? edit;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final edit = this.edit;

    return Scaffold(
      backgroundColor: c.surface100,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                ResultMap(itinerary: itinerary, height: 400, attributionInset: const EdgeInsets.only(bottom: 34)),
                Positioned(
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                  top: top + AppSpacing.s3,
                  child: Row(
                    children: [
                      OtwRoundButton(icon: OtwIcon.back, tooltip: AppCopy.back, onPressed: () => context.pop()),
                      const Spacer(),
                      if (edit != null)
                        OtwRoundButton(
                          icon: OtwIcon.edit,
                          tooltip: AppCopy.editPlan,
                          onPressed: () => context.go(AppRoutes.plan),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.surface100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s1, AppSpacing.screen, AppSpacing.s8),
            sliver: SliverList.list(
              children: [
                Text(AppCopy.resultTitle(itinerary.destinationCity), style: text.headlineMedium?.copyWith(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  AppCopy.resultMeta(DateLabel.long(itinerary.date), itinerary.originLabel, itinerary.vibeLabel, itinerary.budgetLabel),
                  style: text.labelLarge?.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 18),
                ResultStatsRow(
                  freeTime: Clock.duration(itinerary.freeMinutes),
                  cost: Rupiah.short(itinerary.totalCost(choices), free: AppCopy.free),
                  homeArrival: Clock.format(itinerary.homeArrival),
                ),
                const SizedBox(height: 18),
                ResultStatusBanners(itinerary: itinerary, showEditedDrops: edit != null),
                const SizedBox(height: 22),
                OtwSectionTitle(
                  AppCopy.yourPlan,
                  trailing: Text(AppCopy.costNote, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                ),
                const SizedBox(height: AppSpacing.s4),
                TimelineView(
                  itinerary: itinerary,
                  choices: choices,
                  onChoose: onChoose,
                  onOpenStop: (s) => context.push(AppRoutes.stop(s.placeId)),
                  onRemoveStop: edit?.removeStop,
                  onFillMore: edit?.fillMore,
                  onReturnEarlier: edit?.returnEarlier,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: OtwBottomBar(child: bottom),
    );
  }
}
