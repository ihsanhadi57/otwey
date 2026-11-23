import 'package:material_ui/material_ui.dart';

import 'otw_choice_tile.dart';
import 'otw_icon.dart';

/// Satu opsi untuk [OtwChoiceGrid].
class OtwChoice<T> {
  const OtwChoice({
    required this.value,
    required this.label,
    required this.icon,
    this.tint,
  });

  final T value;
  final String label;
  final OtwIcon icon;
  final Color? tint;
}

/// Grid tile tanpa scroll untuk pilih 1 dari 3 sampai 6 opsi berikon.
class OtwChoiceGrid<T> extends StatelessWidget {
  const OtwChoiceGrid({
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.columns = 3,
    super.key,
  });

  final List<OtwChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final choice in choices)
              SizedBox(
                width: width,
                child: OtwChoiceTile(
                  icon: choice.icon,
                  label: choice.label,
                  tint: choice.tint,
                  selected: choice.value == selected,
                  onTap: () => onChanged(choice.value),
                ),
              ),
          ],
        );
      },
    );
  }
}
