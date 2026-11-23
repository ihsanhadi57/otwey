import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Tombol simpan ke wishlist. Hati membesar sebentar saat ditekan.
class HeartButton extends StatefulWidget {
  const HeartButton({required this.saved, required this.onPressed, this.size = 22, super.key});

  final bool saved;
  final VoidCallback onPressed;
  final double size;

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> {
  int _play = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = widget.saved ? AppCopy.removeFromWishlist : AppCopy.saveToWishlist;
    return OtwIconButton(
      tooltip: label,
      isSelected: widget.saved,
      onPressed: () {
        setState(() => _play++);
        widget.onPressed();
      },
      icon: OtwIconView(
        OtwIcon.heart,
        variant: widget.saved ? OtwIconVariant.fill : OtwIconVariant.line,
        size: widget.size,
        color: widget.saved ? c.brand : c.inkMuted,
        play: _play,
      ),
    );
  }
}
