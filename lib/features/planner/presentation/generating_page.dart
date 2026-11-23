import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import 'itinerary_provider.dart';
import 'widgets/generating_steps.dart';
import 'widgets/orbit_oti.dart';
import '../../../core/widgets/otw_press.dart';

/// Loading saat planner menyusun rute. Oti dan langkahnya bergerak berulang.
class GeneratingPage extends ConsumerStatefulWidget {
  const GeneratingPage({super.key});

  @override
  ConsumerState<GeneratingPage> createState() => _GeneratingPageState();
}

class _GeneratingPageState extends ConsumerState<GeneratingPage> {
  /// Animasi langkah tampil minimal sekian supaya tidak berkedip.
  static const _minShow = Duration(milliseconds: 2400);

  Timer? _min;
  bool _minDone = false;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _min = Timer(_minShow, () {
      _minDone = true;
      _maybeOpen();
    });
  }

  /// Pindah ke hasil setelah planner selesai (berhasil atau gagal) dan
  /// animasi minimal sudah lewat. Loading hanya ada di layar ini.
  void _maybeOpen() {
    if (!mounted || _opened || !_minDone) return;
    final state = ref.read(itineraryProvider);
    if (state.isLoading) return;
    _openResult();
  }

  void _openResult() {
    if (!mounted || _opened) return;
    _opened = true;
    context.pushReplacement(AppRoutes.result);
  }

  @override
  void dispose() {
    _min?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    // Mulai menyusun sekarang, dan buka hasil begitu selesai.
    ref.listen(itineraryProvider, (_, _) => _maybeOpen());
    final draft = ref.watch(tripDraftProvider);
    final locked = draft.pins.where((p) => p.isFixedTime).toList();
    final steps = [
      AppCopy.stepRoute,
      if (locked.isNotEmpty) AppCopy.stepLock(Clock.format(locked.first.fixedStart!)),
      AppCopy.stepSearch(draft.vibe.label),
      AppCopy.stepCheck,
    ];
    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          child: Column(
            children: [
              const Spacer(),
              const OrbitOti(),
              const SizedBox(height: AppSpacing.s6),
              Semantics(
                liveRegion: true,
                child: Text(AppCopy.generating, textAlign: TextAlign.center, style: text.titleLarge),
              ),
              const SizedBox(height: 6),
              Text(AppCopy.generatingHint, style: text.bodyLarge?.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpacing.s6),
              GeneratingSteps(steps: steps),
              const Spacer(),
              OtwTextButton(onPressed: _openResult, child: const Text(AppCopy.see)),
            ],
          ),
        ),
      ),
    );
  }
}
