import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../theme/app_colors.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Navigasi bawah 4 tab. Tab aktif = ikon fill oranye, tanpa pill.
class OtwNavBar extends StatelessWidget {
  const OtwNavBar({required this.index, required this.onTap, super.key});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (OtwIcon.home, AppCopy.navHome),
    (OtwIcon.explore, AppCopy.navExplore),
    (OtwIcon.ticket, AppCopy.navTrip),
    (OtwIcon.user, AppCopy.navAccount),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface200,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    active: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final OtwIcon icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  int _play = 0;

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play++;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = widget.active ? c.brand : c.lineStrong;
    return Semantics(
      selected: widget.active,
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: OtwInkWell(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OtwIconView(
              widget.icon,
              variant: widget.active ? OtwIconVariant.fill : OtwIconVariant.line,
              size: 26,
              color: color,
              play: _play,
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.active ? c.brand : c.inkMuted,
                    fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
