import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/floating_symbols.dart';
import '../../../../core/widgets/otw_empty_state.dart';

/// Belum ada trip: Oti tidur dengan huruf "z" melayang.
class TripsEmptyView extends StatelessWidget {
  const TripsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OtwEmptyState(
      mood: OtiMood.zzz,
      title: AppCopy.emptyTripTitle,
      body: AppCopy.emptyTripBody,
      ctaLabel: AppCopy.emptyTripCta,
      onCta: () => context.go(AppRoutes.home),
      secondaryLabel: AppCopy.emptyTripSecondary,
      onSecondary: () => context.go(AppRoutes.explore),
      decoration: FloatingSymbols(
        builder: (i) => Text(
          'z',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontWeight: FontWeight.w700,
            fontSize: 22.0 - i * 4,
            color: c.info,
          ),
        ),
      ),
    );
  }
}
