import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Jenis snackbar. Aksi berbahaya tidak lewat snackbar, pakai dialog.
enum OtwSnackKind { sukses, info, peringatan, gagal }

/// Isi snackbar navy dengan ikon dan satu aksi opsional.
class OtwSnackbarContent extends StatelessWidget {
  const OtwSnackbarContent({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final OtwSnackKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  (OtwIcon, Color) _visual(AppColors c) => switch (kind) {
    OtwSnackKind.sukses => (OtwIcon.done, const Color(0xFF7FD3A8)),
    OtwSnackKind.info => (OtwIcon.heart, const Color(0xFFFF9B73)),
    OtwSnackKind.peringatan => (OtwIcon.clock, c.sun),
    OtwSnackKind.gagal => (OtwIcon.info, const Color(0xFFFF9B73)),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, tone) = _visual(c);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 38),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: OtwIconView(
              icon,
              variant: OtwIconVariant.fill,
              size: 18,
              color: tone,
              knock: c.ink,
              play: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (actionLabel != null)
            OtwTextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: c.sun),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tampilkan snackbar OTWEY. Hilang sendiri dalam 4 detik, satu per satu.
void showOtwSnackBar(
  BuildContext context, {
  required OtwSnackKind kind,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final c = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      elevation: 10,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        0,
        AppSpacing.s6,
        AppSpacing.s3,
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: OtwSnackbarContent(
        kind: kind,
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          messenger.hideCurrentSnackBar();
          onAction?.call();
        },
      ),
    ),
  );
}
