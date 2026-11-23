import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_bottom_bar.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Aksi bawah detail tempat: simpan ke wishlist. Memasukkan ke rencana
/// dilakukan dari halaman Atur rencana ("Ambil dari wishlist"), supaya tempat
/// tidak diam diam masuk ke trip tanpa terlihat.
class PlaceDetailBar extends StatelessWidget {
  const PlaceDetailBar({required this.saved, required this.onToggleSaved, super.key});

  final bool saved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = OtwIconView(
      OtwIcon.heart,
      variant: saved ? OtwIconVariant.fill : OtwIconVariant.line,
      size: 20,
      color: saved ? c.brand : c.onBrand,
      knock: saved ? c.surface100 : c.brand,
    );
    return OtwBottomBar(
      child: saved
          ? OtwOutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: onToggleSaved,
              icon: icon,
              label: const Text(AppCopy.savedInWishlist),
            )
          : OtwFilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: onToggleSaved,
              icon: icon,
              label: const Text(AppCopy.saveToWishlist),
            ),
    );
  }
}
