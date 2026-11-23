import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/widgets/otw_confirm_dialog.dart';
import '../../../core/widgets/otw_snackbar.dart';
import '../../trip_setup/presentation/trip_draft_notifier.dart';
import '../domain/itinerary.dart';
import 'widgets/stay_sheet.dart';

/// Aksi edit di halaman hasil. Semua lewat draft, lalu itineraryProvider
/// menjalankan ulang planner sehingga jam selalu dihitung ulang dan valid.
class ResultEditActions {
  const ResultEditActions(this.context, this.ref, this.itinerary);

  final BuildContext context;
  final WidgetRef ref;
  final Itinerary itinerary;

  TripDraftNotifier get _draft => ref.read(tripDraftProvider.notifier);

  /// Rekomendasi langsung dihapus dengan opsi Batal. Tujuan milik user
  /// (termasuk Wajib) harus dikonfirmasi dulu, tidak pernah hilang diam diam.
  Future<void> removeStop(StopEntry stop) async {
    final pinId = stop.pinId;
    if (pinId != null) {
      final ok = await showOtwConfirmDialog(
        context,
        title: AppCopy.deletePinTitle(stop.title),
        body: AppCopy.deletePinBody,
        confirmLabel: AppCopy.deletePinConfirm,
        cancelLabel: AppCopy.deleteCancel,
        tone: OtwDialogTone.danger,
        mood: OtiMood.mepet,
      );
      if (ok) _draft.removePinFromResult(itinerary, pinId);
      return;
    }
    final previous = ref.read(tripDraftProvider);
    _draft.removeRecommendation(itinerary, stop.placeId);
    if (!context.mounted) return;
    showOtwSnackBar(
      context,
      kind: OtwSnackKind.info,
      message: AppCopy.stopRemoved(stop.title),
      actionLabel: AppCopy.undo,
      onAction: () => _draft.restore(previous),
    );
  }

  /// Ubah lama di satu tempat. Urutan tempat dipertahankan, jam dihitung ulang.
  Future<void> editStay(StopEntry stop) async {
    final minutes = await showStaySheet(context, title: stop.title, start: stop.time, current: stop.minutes);
    if (minutes == null || minutes == stop.minutes) return;
    _draft.setStay(itinerary, stop.pinId ?? stop.placeId, minutes);
  }

  void fillMore() => _draft.fillMore(itinerary);

  void returnEarlier() => _draft.returnEarlier(itinerary);
}
