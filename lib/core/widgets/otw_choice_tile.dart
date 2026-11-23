import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Tile pilihan berikon (pilih 1 dari 3 sampai 6).
///
/// Terpilih: latar putih, garis navy 2 px, ikon fill navy, ikon bergerak sebentar.
/// Tidak terpilih: garis abu tipis, ikon line warna kategori ([tint]).
class OtwChoiceTile extends StatefulWidget {
  const OtwChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
    super.key,
  });

  final OtwIcon icon;
  final String label;
  final bool selected;
  final Color? tint;
  final VoidCallback onTap;

  @override
  State<OtwChoiceTile> createState() => _OtwChoiceTileState();
}

class _OtwChoiceTileState extends State<OtwChoiceTile> {
  int _play = 0;

  void _handleTap() {
    setState(() => _play++);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = widget.selected;
    return Semantics(
      selected: selected,
      button: true,
      child: OtwPressScale(
        child: Material(
          color: c.surface200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            side: BorderSide(
              color: selected ? c.ink : c.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OtwIconView(
                    widget.icon,
                    variant: selected
                        ? OtwIconVariant.fill
                        : OtwIconVariant.line,
                    size: 26,
                    color: selected ? c.ink : (widget.tint ?? c.ink),
                    knock: c.surface200,
                    play: _play,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
