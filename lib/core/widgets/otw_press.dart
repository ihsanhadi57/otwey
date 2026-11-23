import 'package:material_ui/material_ui.dart';

/// Skala saat ditekan. Pengganti highlight abu bawaan Material.
const otwPressScale = 0.97;

/// Mengecilkan [child] sedikit selama jari menekan, lalu kembali mulus.
///
/// Hanya mendengarkan pointer (tidak ikut arena gestur), jadi tap, scroll,
/// dan long press anak tidak terganggu. Kalau jari bergeser jauh (scroll),
/// skala dilepas supaya daftar tidak terlihat "tertahan".
class OtwPressScale extends StatefulWidget {
  const OtwPressScale({required this.child, this.enabled = true, this.scale = otwPressScale, super.key});

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<OtwPressScale> createState() => _OtwPressScaleState();
}

class _OtwPressScaleState extends State<OtwPressScale> {
  static const _slop = 12.0;

  bool _down = false;
  Offset _origin = Offset.zero;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_down && (e.position - _origin).distance > _slop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 80 : 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// InkWell tanpa percikan: isinya mengecil saat ditekan.
class OtwInkWell extends StatelessWidget {
  const OtwInkWell({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.customBorder,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;

  @override
  Widget build(BuildContext context) {
    return OtwPressScale(
      enabled: onTap != null || onLongPress != null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        customBorder: customBorder,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: child,
      ),
    );
  }
}

/// FilledButton yang mengecil saat ditekan.
class OtwFilledButton extends StatelessWidget {
  const OtwFilledButton({required this.onPressed, required this.child, this.style, super.key})
      : icon = null;

  const OtwFilledButton.icon({
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
    super.key,
  }) : child = label;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => OtwPressScale(
        enabled: onPressed != null,
        child: icon == null
            ? FilledButton(onPressed: onPressed, style: style, child: child)
            : FilledButton.icon(onPressed: onPressed, style: style, icon: icon, label: child),
      );
}

/// OutlinedButton yang mengecil saat ditekan.
class OtwOutlinedButton extends StatelessWidget {
  const OtwOutlinedButton({required this.onPressed, required this.child, this.style, super.key})
      : icon = null;

  const OtwOutlinedButton.icon({
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
    super.key,
  }) : child = label;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => OtwPressScale(
        enabled: onPressed != null,
        child: icon == null
            ? OutlinedButton(onPressed: onPressed, style: style, child: child)
            : OutlinedButton.icon(onPressed: onPressed, style: style, icon: icon, label: child),
      );
}

/// TextButton yang mengecil saat ditekan.
class OtwTextButton extends StatelessWidget {
  const OtwTextButton({required this.onPressed, required this.child, this.style, super.key})
      : icon = null;

  const OtwTextButton.icon({
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
    super.key,
  }) : child = label;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => OtwPressScale(
        enabled: onPressed != null,
        child: icon == null
            ? TextButton(onPressed: onPressed, style: style, child: child)
            : TextButton.icon(onPressed: onPressed, style: style, icon: icon, label: child),
      );
}

/// IconButton yang mengecil saat ditekan.
class OtwIconButton extends StatelessWidget {
  const OtwIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.constraints,
    this.isSelected,
    this.focusNode,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final BoxConstraints? constraints;
  final bool? isSelected;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => OtwPressScale(
        enabled: onPressed != null,
        scale: 0.9,
        child: IconButton(
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          constraints: constraints,
          isSelected: isSelected,
          focusNode: focusNode,
        ),
      );
}
