import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/origin_point.dart';
import '../../../../core/widgets/otw_press.dart';

/// Satu titik berangkat di daftar. Terpilih = ikon fill oranye dan centang.
class OriginOptionTile extends StatefulWidget {
  const OriginOptionTile({
    required this.origin,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
    super.key,
  });

  final OriginPoint origin;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  State<OriginOptionTile> createState() => _OriginOptionTileState();
}

class _OriginOptionTileState extends State<OriginOptionTile> {
  int _play = 0;

  static OtwIcon _icon(OriginKind kind) => switch (kind) {
        OriginKind.home => OtwIcon.home,
        OriginKind.work => OtwIcon.briefcase,
        OriginKind.station => OtwIcon.station,
        OriginKind.other => OtwIcon.pin,
        OriginKind.current => OtwIcon.locate,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final on = widget.selected;
    return Semantics(
      selected: on,
      button: true,
      child: OtwInkWell(
        onTap: () {
          setState(() => _play++);
          widget.onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: widget.showDivider ? Border(bottom: BorderSide(color: c.surface300)) : null,
          ),
          child: Row(
            children: [
              OtwIconView(
                _icon(widget.origin.kind),
                variant: on ? OtwIconVariant.fill : OtwIconVariant.line,
                size: 24,
                color: c.ink,
                play: _play,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.origin.label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.origin.address, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              if (on) OtwIconView(OtwIcon.done, variant: OtwIconVariant.fill, size: 22, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}
