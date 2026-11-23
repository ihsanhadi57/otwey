import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/otw_map.dart';
import '../../domain/itinerary.dart';

/// Peta rute hasil di kota tujuan: stasiun, tempat bernomor, tujuan terkunci,
/// tersambung garis rute sesuai urutan kunjungan.
class ResultMap extends StatelessWidget {
  const ResultMap({
    required this.itinerary,
    this.height = 400,
    this.interactive = true,
    this.attributionInset = EdgeInsets.zero,
    super.key,
  });

  final Itinerary itinerary;

  /// Lihat [OtwMap.attributionInset].
  final EdgeInsets attributionInset;
  final double height;
  final bool interactive;

  static List<OtwMapPoint> pointsOf(Itinerary itinerary) => [
    for (final p in itinerary.route)
      OtwMapPoint(
        lat: p.lat,
        lng: p.lng,
        number: p.number,
        kind: switch (p.kind) {
          RoutePointKind.station => OtwMarkerKind.station,
          RoutePointKind.stop => OtwMarkerKind.stop,
          RoutePointKind.locked => OtwMarkerKind.locked,
        },
      ),
  ];

  @override
  Widget build(BuildContext context) => OtwMap(
    height: height,
    points: pointsOf(itinerary),
    center: AppConfig.cityCenter(itinerary.destinationCity),
    showRoute: true,
    interactive: interactive,
    attributionInset: attributionInset,
  );
}
