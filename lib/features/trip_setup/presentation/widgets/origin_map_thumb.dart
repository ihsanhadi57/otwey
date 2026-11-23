import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_map.dart';
import '../../../../core/widgets/otw_press.dart';

/// Pratinjau peta di halaman pilih titik berangkat. Ketuk untuk membuka peta
/// penuh dan memilih titik di sana.
class OriginMapThumb extends StatelessWidget {
  const OriginMapThumb({
    required this.city,
    required this.onTap,
    this.point,
    this.me,
    super.key,
  });

  final String city;
  final ({double lat, double lng})? point;
  final ({double lat, double lng})? me;
  final VoidCallback onTap;

  static const _height = 168.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final at = point ?? me ?? AppConfig.cityCenter(city);
    return Semantics(
      button: true,
      label: AppCopy.pickOnMap,
      excludeSemantics: true,
      child: OtwInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: OtwMap(
                    center: at,
                    me: me,
                    interactive: false,
                    refitOnChange: false,
                    points: [
                      if (point != null)
                        OtwMapPoint(lat: point!.lat, lng: point!.lng, kind: OtwMarkerKind.place),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.s3,
                bottom: AppSpacing.s3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface200.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(color: c.ink.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OtwIconView(OtwIcon.explore, size: 18, color: c.brand),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          AppCopy.pickOnMap,
                          style: text.labelLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
