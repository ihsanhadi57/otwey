import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../location/my_location.dart';
import '../theme/app_colors.dart';
import 'otw_icon.dart';
import 'otw_snackbar.dart';
import 'otw_press.dart';

/// Tombol "lokasi saya" di atas peta. Minta izin bila perlu, lalu memanggil
/// [onLocated] dengan posisi user. Gagal = snackbar dengan aksi ke pengaturan.
class OtwLocateButton extends ConsumerWidget {
  const OtwLocateButton({required this.onLocated, this.size = 52, super.key});

  final void Function(double lat, double lng) onLocated;
  final double size;

  Future<void> _locate(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(myLocationProvider.notifier);
    final status = await notifier.locate();
    if (!context.mounted) return;
    final loc = ref.read(myLocationProvider);
    if (status == LocationStatus.ready && loc.hasFix) {
      onLocated(loc.lat!, loc.lng!);
      return;
    }
    final message = switch (status) {
      LocationStatus.serviceOff => AppCopy.locationOff,
      LocationStatus.deniedForever => AppCopy.locationDeniedForever,
      LocationStatus.denied => AppCopy.locationDenied,
      _ => AppCopy.locationFailed,
    };
    final canFix = status == LocationStatus.serviceOff || status == LocationStatus.deniedForever;
    showOtwSnackBar(
      context,
      kind: OtwSnackKind.peringatan,
      message: message,
      actionLabel: canFix ? AppCopy.openSettings : null,
      onAction: canFix ? () => notifier.openSettings(status) : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final loading = ref.watch(myLocationProvider.select((l) => l.status == LocationStatus.loading));
    return Tooltip(
      message: AppCopy.myLocation,
      child: Material(
        color: c.surface200,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: c.ink.withValues(alpha: 0.3),
        child: OtwInkWell(
          customBorder: const CircleBorder(),
          onTap: loading ? null : () => _locate(context, ref),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: c.brand),
                    )
                  : OtwIconView(OtwIcon.locate, size: 24, color: c.ink, semanticLabel: AppCopy.myLocation),
            ),
          ),
        ),
      ),
    );
  }
}
