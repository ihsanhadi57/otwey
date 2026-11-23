/// Rute transum offline antar tempat di satu kota, hasil `tool/city_transit.dart`
/// (GTFS TransJakarta + MRT/LRT/KRL). Data turunan, dibaca planner supaya
/// pilihan transum punya waktu dan langkah yang jelas tanpa API.
library;

import '../../../core/utils/geo.dart';

/// Moda satu langkah, sama dengan nilai `mode` di file JSON.
enum CityTransitMode {
  walk,
  bus,
  brt,
  mrt,
  lrt,
  krl;

  static CityTransitMode fromCode(String? c) =>
      values.firstWhere((m) => m.name == c, orElse: () => bus);

  bool get isRail => this == mrt || this == lrt || this == krl;
}

class CityTransitStep {
  const CityTransitStep({
    required this.mode,
    required this.from,
    required this.to,
    required this.minutes,
    this.line,
    this.short,
    this.color,
    this.wait = 0,
    this.stops = 0,
  });

  final CityTransitMode mode;
  final String from;
  final String to;

  /// Menit di kendaraan atau menit jalan kaki.
  final int minutes;
  final String? line;
  final String? short;

  /// "RRGGBB" kalau ada.
  final String? color;

  /// Perkiraan menunggu (setengah headway).
  final int wait;
  final int stops;

  bool get isWalk => mode == CityTransitMode.walk;

  factory CityTransitStep.fromJson(Map<String, dynamic> j) => CityTransitStep(
        mode: CityTransitMode.fromCode(j['mode'] as String?),
        from: j['from'] as String? ?? '',
        to: j['to'] as String? ?? '',
        minutes: (j['minutes'] as num?)?.round() ?? 0,
        line: j['line'] as String?,
        short: j['short'] as String?,
        color: j['color'] as String?,
        wait: (j['wait'] as num?)?.round() ?? 0,
        stops: (j['stops'] as num?)?.round() ?? 0,
      );
}

class CityTransitRoute {
  const CityTransitRoute({required this.minutes, required this.fare, required this.steps});

  /// Total menit termasuk jalan kaki dan menunggu.
  final int minutes;
  final int fare;
  final List<CityTransitStep> steps;

  bool get usesRail => steps.any((s) => s.mode.isRail);

  static CityTransitRoute fromJson(Map<String, dynamic> r) => CityTransitRoute(
        minutes: (r['minutes'] as num).round(),
        fare: (r['fare'] as num?)?.round() ?? 0,
        steps: [
          for (final s in (r['steps'] as List).cast<Map<String, dynamic>>()) CityTransitStep.fromJson(s),
        ],
      );
}

/// Titik ujung akses stasiun (stasiun rel atau halte BRT) dengan rute ke dan
/// dari stasiun Whoosh. User menuju titik ini dulu (jalan kaki atau ojol).
class StationAnchor {
  const StationAnchor({
    required this.name,
    required this.lat,
    required this.lng,
    this.isRail = false,
    this.toStation,
    this.fromStation,
  });

  final String name;

  /// Stasiun MRT, LRT, atau KRL (selain itu halte BRT).
  final bool isRail;
  final double lat;
  final double lng;
  final CityTransitRoute? toStation;
  final CityTransitRoute? fromStation;
}

/// Rute dari titik bebas (misalnya lokasi user) ke stasiun, atau sebaliknya.
class AnchoredRoute {
  const AnchoredRoute({required this.anchor, required this.route, required this.mileMinutes, required this.mileCost, required this.mileByWalk});

  final StationAnchor anchor;
  final CityTransitRoute route;
  final int mileMinutes;
  final int mileCost;
  final bool mileByWalk;

  int get minutes => mileMinutes + route.minutes;
  int get fare => mileCost + route.fare;
}

/// Indeks rute per pasangan titik. Titik dicocokkan lewat koordinat, karena id
/// tempat beda antara mode seed (key) dan Supabase (uuid).
class CityTransitIndex {
  CityTransitIndex(this._points, this._routes, [this._anchors = const {}]);

  static final empty = CityTransitIndex(const [], const {});

  /// Per indeks titik stasiun: titik ujung aksesnya.
  final Map<int, List<StationAnchor>> _anchors;

  /// Titik lebih jauh dari ini dari titik terindeks dianggap tidak cocok.
  static const matchKm = 0.08;

  final List<({double lat, double lng})> _points;
  final Map<(int, int), CityTransitRoute> _routes;

  bool get isEmpty => _routes.isEmpty;

  factory CityTransitIndex.fromJson(Map<String, dynamic> json) {
    final points = [
      for (final p in (json['points'] as List? ?? const []).cast<Map<String, dynamic>>())
        (lat: (p['lat'] as num).toDouble(), lng: (p['lng'] as num).toDouble()),
    ];
    final routes = <(int, int), CityTransitRoute>{};
    for (final r in (json['routes'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      routes[((r['from'] as num).toInt(), (r['to'] as num).toInt())] = CityTransitRoute.fromJson(r);
    }
    final anchors = <int, List<StationAnchor>>{};
    for (final a in (json['access'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      anchors[(a['station'] as num).toInt()] = [
        for (final x in (a['anchors'] as List).cast<Map<String, dynamic>>())
          StationAnchor(
            name: x['name'] as String,
            isRail: x['rail'] == true,
            lat: (x['lat'] as num).toDouble(),
            lng: (x['lng'] as num).toDouble(),
            toStation: x['to'] == null ? null : CityTransitRoute.fromJson((x['to'] as Map).cast<String, dynamic>()),
            fromStation: x['from'] == null ? null : CityTransitRoute.fromJson((x['from'] as Map).cast<String, dynamic>()),
          ),
      ];
    }
    return CityTransitIndex(points, routes, anchors);
  }

  int? _pointAt(double lat, double lng) {
    int? best;
    var bestKm = matchKm;
    for (var i = 0; i < _points.length; i++) {
      final km = haversineKm(lat, lng, _points[i].lat, _points[i].lng);
      if (km <= bestKm) {
        bestKm = km;
        best = i;
      }
    }
    return best;
  }

  CityTransitRoute? find(double fromLat, double fromLng, double toLat, double toLng) {
    if (isEmpty) return null;
    final a = _pointAt(fromLat, fromLng);
    if (a == null) return null;
    final b = _pointAt(toLat, toLng);
    if (b == null) return null;
    return _routes[(a, b)];
  }

  /// Berapa stasiun rel terdekat yang boleh dicapai dengan ojol.
  static const ojolRailCandidates = 3;

  /// Rute transum terbaik dari titik bebas ke stasiun (atau dari stasiun ke
  /// titik bebas). [firstMile] memberi menit dan ongkos titik bebas ke ujung
  /// akses (jalan kaki atau ojol). Null kalau ujung lain bukan stasiun berindeks.
  ///
  /// Ujung yang dipertimbangkan: semua yang terjangkau jalan kaki (stasiun rel
  /// atau halte BRT), ditambah [ojolRailCandidates] stasiun rel terdekat. Jadi
  /// ojol hanya dipakai untuk ke stasiun MRT/LRT/KRL terdekat, bukan sampai
  /// dekat stasiun Whoosh.
  AnchoredRoute? viaStation(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng, {
    required ({int minutes, int cost, bool walk}) Function(double aLat, double aLng, double bLat, double bLng) firstMile,
  }) {
    if (_anchors.isEmpty) return null;
    final toIdx = _pointAt(toLat, toLng);
    final fromIdx = _pointAt(fromLat, fromLng);
    final toStation = toIdx != null && _anchors.containsKey(toIdx);
    final fromStation = fromIdx != null && _anchors.containsKey(fromIdx);
    if (toStation == fromStation) return null;
    final anchors = _anchors[toStation ? toIdx : fromIdx]!;
    final (pLat, pLng) = toStation ? (fromLat, fromLng) : (toLat, toLng);
    final nearestRail = [
      for (final a in anchors)
        if (a.isRail && (toStation ? a.toStation : a.fromStation) != null) a,
    ]..sort((a, b) => haversineKm(pLat, pLng, a.lat, a.lng).compareTo(haversineKm(pLat, pLng, b.lat, b.lng)));
    final ojolAllowed = nearestRail.take(ojolRailCandidates).toSet();
    AnchoredRoute? best;
    for (final a in anchors) {
      final route = toStation ? a.toStation : a.fromStation;
      if (route == null) continue;
      final mile = toStation ? firstMile(fromLat, fromLng, a.lat, a.lng) : firstMile(a.lat, a.lng, toLat, toLng);
      if (!mile.walk && !ojolAllowed.contains(a)) continue;
      final candidate = AnchoredRoute(
        anchor: a,
        route: route,
        mileMinutes: mile.minutes,
        mileCost: mile.cost,
        mileByWalk: mile.walk,
      );
      if (best == null || candidate.minutes < best.minutes) best = candidate;
    }
    return best;
  }
}
