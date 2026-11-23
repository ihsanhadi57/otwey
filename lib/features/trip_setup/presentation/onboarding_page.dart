import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_oti.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/otw_press.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    void start() => context.go(AppRoutes.home);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const OtweyLogo(height: 28),
                  OtwTextButton(onPressed: start, child: const Text(AppCopy.skip)),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: c.sun, borderRadius: BorderRadius.circular(32)),
                  alignment: Alignment.center,
                  child: const AnimatedOti(mood: OtiMood.happy, motion: OtiMotion.bob, size: 200),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(AppCopy.onboardingTitle, style: text.headlineMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(AppCopy.onboardingSubtitle, style: text.bodyLarge?.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpacing.s6),
              OtwFilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: start,
                child: const Text(AppCopy.onboardingCta),
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}
