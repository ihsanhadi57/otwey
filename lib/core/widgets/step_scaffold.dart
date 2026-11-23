import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_press.dart';

/// Kerangka layar langkah: judul, subjudul, isi, dan CTA lebar penuh di bawah.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.title,
    required this.ctaLabel,
    required this.onCta,
    this.subtitle,
    this.child,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final String ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  subtitle!,
                  style: text.bodyLarge?.copyWith(color: context.colors.inkMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.s6),
              Expanded(child: child ?? const SizedBox.shrink()),
              OtwFilledButton(onPressed: onCta, child: Text(ctaLabel)),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}
