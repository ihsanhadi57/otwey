import 'package:material_ui/material_ui.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'animated_oti.dart';
import 'otw_press.dart';

/// Nada tombol utama dialog.
enum OtwDialogTone {
  /// Aksi biasa, oranye.
  action,

  /// Menghapus atau membuang sesuatu, merah.
  danger,
}

/// Dialog konfirmasi dengan Oti di atas kartu.
class OtwConfirmDialog extends StatelessWidget {
  const OtwConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    this.tone = OtwDialogTone.action,
    this.mood = OtiMood.mepet,
    super.key,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final OtwDialogTone tone;
  final OtiMood mood;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final halo = switch (mood) {
      OtiMood.zzz => c.infoTint,
      OtiMood.mepet => tone == OtwDialogTone.danger ? c.brandTint : c.sunTint,
      _ => c.sunTint,
    };
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 56),
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
            decoration: BoxDecoration(
              color: c.surface200,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center, style: text.titleLarge),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: c.inkMuted, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.s6),
                OtwFilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tone == OtwDialogTone.danger ? c.danger : c.brand,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
                const SizedBox(height: AppSpacing.s2),
                OtwTextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: c.ink,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: halo,
              shape: BoxShape.circle,
              border: Border.all(color: c.surface200, width: 6),
            ),
            child: AnimatedOti(mood: mood, motion: OtiMotion.worry, size: 80),
          ),
        ],
      ),
    );
  }
}

/// Tampilkan [OtwConfirmDialog]. Hasil true kalau user menekan tombol utama.
Future<bool> showOtwConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  OtwDialogTone tone = OtwDialogTone.action,
  OtiMood mood = OtiMood.mepet,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => OtwConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
      mood: mood,
    ),
  );
  return result ?? false;
}
