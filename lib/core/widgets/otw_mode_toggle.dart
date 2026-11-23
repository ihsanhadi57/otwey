import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Satu opsi [OtwModeToggle], misalnya Ojol atau Transum.
class OtwModeOption<T> {
  const OtwModeOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.meta,
  });

  final T value;
  final String label;
  final OtwIcon icon;

  /// Info pendek di baris kedua, misalnya "22 mnt · ± Rp32rb".
  final String meta;
}

/// Segmented versi perbandingan: setiap opsi membawa durasi dan ongkos.
/// Terpilih = navy penuh, sama dengan segmented biasa.
class OtwModeToggle<T> extends StatefulWidget {
  const OtwModeToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final List<OtwModeOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  State<OtwModeToggle<T>> createState() => _OtwModeToggleState<T>();
}

class _OtwModeToggleState<T> extends State<OtwModeToggle<T>> {
  final Map<int, int> _plays = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: c.surface300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: _option(context, i, c, text)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, int i, AppColors c, TextTheme text) {
    final o = widget.options[i];
    final on = o.value == widget.selected;
    final bg = on ? c.ink : c.surface300;
    final fg = on ? c.surface200 : c.inkMuted;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _plays[i] = (_plays[i] ?? 0) + 1);
            widget.onChanged(o.value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OtwIconView(
                      o.icon,
                      variant: on ? OtwIconVariant.fill : OtwIconVariant.line,
                      size: 20,
                      color: fg,
                      knock: bg,
                      play: _plays[i] ?? 0,
                    ),
                    const SizedBox(width: 6),
                    Text(o.label, style: text.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  o.meta,
                  style: AppTypography.timeSm(color: on ? c.surface300 : c.inkMuted)
                      .copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
