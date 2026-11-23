import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/category_visual.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place.dart';

/// Area foto di atas detail tempat. Sementara ilustrasi kategori.
///
/// TODO(hadi): tampilkan `place.photoUrl` (galeri geser) kalau sudah ada foto.
class PlacePhotoHeader extends StatelessWidget {
  const PlacePhotoHeader({required this.place, this.height = 280, super.key});

  final Place place;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = place.categoryCodes.first;
    return Container(
      height: height,
      width: double.infinity,
      color: CategoryVisual.softBackground(c, code),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          OtwIconView(CategoryVisual.icon(code), size: 88, color: CategoryVisual.tint(c, code)),
          const SizedBox(height: 10),
          Text(
            AppCopy.photoSoon,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
