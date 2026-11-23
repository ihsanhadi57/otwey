import 'package:material_ui/material_ui.dart';

import '../assets/app_assets.dart';
import '../copy/app_copy.dart';
import 'otw_empty_state.dart';

/// Gagal ambil data: Oti mepet, penjelasan, satu tombol coba lagi.
class OtwErrorView extends StatelessWidget {
  const OtwErrorView({required this.onRetry, this.body, super.key});

  final VoidCallback onRetry;
  final String? body;

  @override
  Widget build(BuildContext context) => OtwEmptyState(
        mood: OtiMood.mepet,
        title: AppCopy.failedRoute,
        body: body ?? AppCopy.errorConnection,
        ctaLabel: AppCopy.retry,
        onCta: onRetry,
      );
}