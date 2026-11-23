import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_symbols.dart';
import '../../../../core/widgets/otw_empty_state.dart';
import '../../../../core/widgets/otw_icon.dart';

/// Wishlist kosong: Oti bernapas dengan hati kecil melayang.
class WishlistEmptyView extends StatelessWidget {
  const WishlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OtwEmptyState(
      mood: OtiMood.happy,
      title: AppCopy.emptyWishlistTitle,
      body: AppCopy.emptyWishlistBody,
      ctaLabel: AppCopy.emptyWishlistCta,
      onCta: () => context.go(AppRoutes.explore),
      decoration: FloatingSymbols(
        origin: const Alignment(-0.45, 0),
        drift: const Offset(10, -54),
        builder: (i) => OtwIconView(OtwIcon.heart, variant: OtwIconVariant.fill, size: 22.0 - i * 4, color: c.brand),
      ),
    );
  }
}
