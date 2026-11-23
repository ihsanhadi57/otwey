import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/copy/app_copy.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/step_scaffold.dart';
import '../domain/trip_direction.dart';
import 'trip_draft_notifier.dart';
import '../../../core/widgets/otw_press.dart';

class DirectionPage extends ConsumerWidget {
  const DirectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final notifier = ref.read(tripDraftProvider.notifier);

    return StepScaffold(
      title: AppCopy.directionTitle,
      ctaLabel: AppCopy.next,
      onCta: () => context.push(AppRoutes.time),
      child: Column(
        children: [
          _DirectionOption(
            label: AppCopy.toBandung,
            selected: draft.direction == TripDirection.jakartaToBandung,
            onTap: () => notifier.setDirection(TripDirection.jakartaToBandung),
          ),
          const SizedBox(height: AppSpacing.s3),
          _DirectionOption(
            label: AppCopy.toJakarta,
            selected: draft.direction == TripDirection.bandungToJakarta,
            onTap: () => notifier.setDirection(TripDirection.bandungToJakarta),
          ),
        ],
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  const _DirectionOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.brandTint : c.surface200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: selected ? c.brand : c.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Row(
              children: [
                Icon(
                  Icons.train_rounded,
                  color: selected ? c.brandStrong : c.inkMuted,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? c.brandStrong : c.ink,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
