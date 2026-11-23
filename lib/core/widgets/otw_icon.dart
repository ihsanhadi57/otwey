import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'otw_icon_data.dart';

export 'otw_icon_data.dart' show OtwIcon;

/// Line untuk keadaan normal, fill untuk aktif atau terpilih.
enum OtwIconVariant { line, fill }

/// Ikon OTWEY (grid 24, garis 2 px). Sumber bentuk: `otw_icon_data.dart`.
///
/// Naikkan [play] setiap kali user memilih ikon ini supaya ikon bergerak sebentar
/// (asap mangkok naik, jendela gedung berkedip, bianglala berputar, dan seterusnya).
/// Gerak dimatikan otomatis kalau user menyalakan "kurangi gerakan".
class OtwIconView extends StatefulWidget {
  const OtwIconView(
    this.icon, {
    this.variant = OtwIconVariant.line,
    this.size = 24,
    this.color,
    this.knock,
    this.play = 0,
    this.semanticLabel,
    super.key,
  });

  final OtwIcon icon;
  final OtwIconVariant variant;
  final double size;

  /// Warna garis dan isi. Default: warna IconTheme, lalu ink.
  final Color? color;

  /// Warna potongan di varian fill. Samakan dengan warna latar di belakang ikon.
  final Color? knock;

  final int play;

  /// Isi kalau ikon berdiri sendiri tanpa teks. Kosong = dekoratif.
  final String? semanticLabel;

  @override
  State<OtwIconView> createState() => _OtwIconViewState();
}

class _OtwIconViewState extends State<OtwIconView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant OtwIconView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.play != oldWidget.play && widget.play > 0 && !reduce) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? IconTheme.of(context).color ?? context.colors.ink;
    final knock = widget.knock ?? context.colors.surface200;
    final spec = otwIconSpecs[widget.icon]!;
    final fill = widget.variant == OtwIconVariant.fill;

    final layers = [
      for (final layer in spec.layers)
        _AnimatedLayer(
          controller: _controller,
          layer: layer,
          size: widget.size,
          svg: _svg(layer.body, color, knock, fill),
        ),
    ];

    final icon = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => _groupMotion(
          spec.motion,
          _controller.isAnimating ? _controller.value : null,
          widget.size,
          child!,
        ),
        child: Stack(children: layers),
      ),
    );

    if (widget.semanticLabel == null) {
      return ExcludeSemantics(child: icon);
    }
    return Semantics(label: widget.semanticLabel, image: true, child: icon);
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _svg(String body, Color color, Color knock, bool fill) {
    final c = _hex(color);
    final k = _hex(knock);
    final filled = body
        .replaceAll('{FB}', fill ? c : 'none')
        .replaceAll('{KI}', fill ? k : c)
        .replaceAll('{FS}', fill ? c : k)
        .replaceAll('{KS}', fill ? k : c)
        .replaceAll('{FP}', fill ? c : k);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="$c" stroke-width="2" stroke-linecap="round" '
        'stroke-linejoin="round">$filled</svg>';
  }
}

/// Gerak ikon utuh. [t] null = diam.
Widget _groupMotion(OtwIconMotion motion, double? t, double size, Widget child) {
  if (t == null || motion == OtwIconMotion.none) return child;
  final unit = size / 24;
  final g = (t / 0.62).clamp(0.0, 1.0);
  final wave = math.sin(math.pi * g);
  switch (motion) {
    case OtwIconMotion.pop:
      final s = g < 0.4
          ? 1 + 0.22 * (g / 0.4)
          : g < 0.7
              ? 1.22 - 0.28 * ((g - 0.4) / 0.3)
              : 0.94 + 0.06 * ((g - 0.7) / 0.3);
      return Transform.scale(scale: s, child: child);
    case OtwIconMotion.popSoft:
      return Transform.scale(scale: 1 + 0.1 * wave, child: child);
    case OtwIconMotion.bounce:
      return Transform.translate(offset: Offset(0, -3 * unit * wave), child: child);
    case OtwIconMotion.wiggle:
      final deg = 12 * math.sin(3 * math.pi * g) * (1 - g);
      return Transform.rotate(angle: deg * math.pi / 180, child: child);
    case OtwIconMotion.spin:
      final s = (t / 0.78).clamp(0.0, 1.0);
      return Transform.rotate(
        angle: 2 * math.pi * Curves.easeOutCubic.transform(s),
        child: child,
      );
    case OtwIconMotion.ring:
      final deg = 16 * math.sin(4 * math.pi * g) * (1 - g);
      return Transform.rotate(
        angle: deg * math.pi / 180,
        alignment: Alignment.topCenter,
        child: child,
      );
    case OtwIconMotion.drop:
      final dy = -5 * unit * (1 - Curves.bounceOut.transform(g));
      return Transform.translate(offset: Offset(0, dy), child: child);
    case OtwIconMotion.drive:
      final dx = 2.5 * unit * math.sin(2 * math.pi * g) * (1 - g * 0.5);
      return Transform.translate(offset: Offset(-dx, 0), child: child);
    case OtwIconMotion.nudge:
      return Transform.translate(offset: Offset(3 * unit * wave, 0), child: child);
    case OtwIconMotion.flip:
      final s = (t / 0.5).clamp(0.0, 1.0);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(math.cos(2 * math.pi * s), 1, 1),
        child: child,
      );
    case OtwIconMotion.none:
      return child;
  }
}

/// Satu lapisan SVG. Lapisan bergerak (asap, matahari, dan lain lain) punya animasi sendiri.
class _AnimatedLayer extends StatelessWidget {
  const _AnimatedLayer({
    required this.controller,
    required this.layer,
    required this.size,
    required this.svg,
  });

  final AnimationController controller;
  final OtwIconLayer layer;
  final double size;
  final String svg;

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.string(svg, width: size, height: size);
    final motion = layer.motion;
    if (motion == null) return picture;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.isAnimating) return child!;
        final lt = ((controller.value - layer.delay * 0.13) / 0.74).clamp(0.0, 1.0);
        return _layerMotion(motion, lt, size / 24, child!);
      },
      child: picture,
    );
  }
}

Widget _layerMotion(OtwLayerMotion motion, double lt, double unit, Widget child) {
  switch (motion) {
    case OtwLayerMotion.steam:
      double dy;
      double op;
      if (lt < 0.45) {
        dy = -3 * (lt / 0.45);
        op = 1 - 0.75 * (lt / 0.45);
      } else if (lt < 0.5) {
        dy = 2;
        op = 0;
      } else {
        dy = 2 * (1 - (lt - 0.5) / 0.5);
        op = (lt - 0.5) / 0.5;
      }
      return Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, dy * unit), child: child),
      );
    case OtwLayerMotion.sun:
      final e = Curves.easeOut.transform(lt);
      return Opacity(
        opacity: 0.2 + 0.8 * e,
        child: Transform.translate(offset: Offset(0, 5 * unit * (1 - e)), child: child),
      );
    case OtwLayerMotion.blink:
      final op = lt < 0.4 ? 1 - 0.9 * (lt / 0.4) : 0.1 + 0.9 * ((lt - 0.4) / 0.6);
      return Opacity(opacity: op.clamp(0.0, 1.0), child: child);
    case OtwLayerMotion.wheel:
      return Transform.rotate(
        angle: math.pi * Curves.easeOutCubic.transform(lt),
        alignment: const Alignment(0, -0.2083),
        child: child,
      );
    case OtwLayerMotion.chop:
      final deg = lt < 0.3
          ? -14 * (lt / 0.3)
          : lt < 0.6
              ? -14 + 20 * ((lt - 0.3) / 0.3)
              : 6 * (1 - (lt - 0.6) / 0.4);
      return Transform.rotate(
        angle: deg * math.pi / 180,
        alignment: const Alignment(0.0417, -0.2917),
        child: child,
      );
    case OtwLayerMotion.bow:
      return Transform.scale(
        scale: 1 + 0.35 * math.sin(math.pi * lt),
        alignment: const Alignment(0, -0.3667),
        child: child,
      );
    case OtwLayerMotion.dot:
      return Transform.translate(
        offset: Offset(0, -3 * unit * math.sin(math.pi * lt)),
        child: child,
      );
  }
}
