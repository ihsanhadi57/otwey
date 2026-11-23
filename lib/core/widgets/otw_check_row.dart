import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Baris checklist untuk pilih banyak. Terpilih = ikon fill dan centang navy.
class OtwCheckRow extends StatefulWidget {
  const OtwCheckRow({
    required this.icon,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.description,
    this.showDivider = true,
    super.key,
  });

  final OtwIcon icon;
  final String label;
  final String? description;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  State<OtwCheckRow> createState() => _OtwCheckRowState();
}

class _OtwCheckRowState extends State<OtwCheckRow> {
  int _play = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      checked: widget.checked,
      button: true,
      child: OtwInkWell(
        onTap: () {
          setState(() => _play++);
          widget.onChanged(!widget.checked);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 10),
          decoration: BoxDecoration(
            border: widget.showDivider
                ? Border(top: BorderSide(color: c.surface300))
                : null,
          ),
          child: Row(
            children: [
              OtwIconView(
                widget.icon,
                variant: widget.checked ? OtwIconVariant.fill : OtwIconVariant.line,
                size: 28,
                color: c.ink,
                play: _play,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    if (widget.description != null)
                      Text(widget.description!, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              _CheckMark(checked: widget.checked, play: _play),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.checked, required this.play});

  final bool checked;
  final int play;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (checked) {
      return OtwIconView(OtwIcon.done, variant: OtwIconVariant.fill, size: 24, color: c.ink, play: play);
    }
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.lineStrong.withValues(alpha: 0.5), width: 2),
      ),
    );
  }
}
