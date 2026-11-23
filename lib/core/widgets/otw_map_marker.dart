import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'otw_icon.dart';

/// Jenis penanda di peta.
enum OtwMarkerKind { stop, station, locked, place, me }

/// Tampilan satu penanda peta bergaya OTWEY (bulat bernomor, stasiun, kunci, pin).
class OtwMapMarkerView extends StatelessWidget {
  const OtwMapMarkerView({required this.kind, this.number, this.label, super.key});

  /// Ukuran kotak penanda. Label (kalau ada) tampil di bawahnya.
  static const size = 36.0;

  final OtwMarkerKind kind;
  final int? number;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget dot = switch (kind) {
      OtwMarkerKind.stop => _circle(
          c.brand,
          Text(
            '${number ?? ''}',
            style: TextStyle(color: c.onBrand, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          c,
        ),
      OtwMarkerKind.station => _circle(c.ink, OtwIconView(OtwIcon.train, size: 16, color: c.surface200), c),
      OtwMarkerKind.locked => _circle(
          c.ink,
          OtwIconView(OtwIcon.lock, variant: OtwIconVariant.fill, size: 15, color: c.surface200, knock: c.ink),
          c),
      OtwMarkerKind.place => OtwIconView(OtwIcon.pin, variant: OtwIconVariant.fill, size: 32, color: c.brand),
      OtwMarkerKind.me => Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: c.info,
            shape: BoxShape.circle,
            border: Border.all(color: c.surface200, width: 3),
            boxShadow: [BoxShadow(color: c.info.withValues(alpha: 0.3), blurRadius: 0, spreadRadius: 8)],
          ),
        ),
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          dot,
          if (label != null)
            Positioned(
              top: size,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surface200,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.12), blurRadius: 6)],
                ),
                child: Text(
                  label!,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circle(Color bg, Widget child, AppColors c) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: c.surface200, width: 2.5),
          boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      );
}
