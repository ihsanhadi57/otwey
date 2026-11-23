import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Satu opsi segmented.
class OtwSegment<T> {
  const OtwSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final OtwIcon? icon;
}

/// Pilih 1 dari 2 atau 3 opsi teks. Terpilih = navy penuh (aturan input OTWEY).
class OtwSegmented<T> extends StatelessWidget {
  const OtwSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final List<OtwSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Theme.of(context).textTheme.labelLarge;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: c.surface300,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            for (final s in segments)
              Expanded(
                child: _SegmentButton(
                  label: s.label,
                  icon: s.icon,
                  selected: s.value == selected,
                  style: label,
                  onTap: () => onChanged(s.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.style,
  });

  final String label;
  final OtwIcon? icon;
  final bool selected;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.surface200 : c.inkMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.ink : Colors.transparent,
        shape: const StadiumBorder(),
        child: OtwInkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  OtwIconView(
                    icon!,
                    variant: selected ? OtwIconVariant.fill : OtwIconVariant.line,
                    size: 14,
                    color: fg,
                    knock: c.ink,
                  ),
                  const SizedBox(width: AppSpacing.s1),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(color: fg),
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
