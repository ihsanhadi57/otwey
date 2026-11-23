import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../copy/app_copy.dart';
import '../theme/app_colors.dart';
import 'otw_map_marker.dart';

export 'otw_map_marker.dart' show OtwMarkerKind;

/// Satu titik di [OtwMap]. Koordinat dalam derajat WGS84.
class OtwMapPoint {
  const OtwMapPoint({
    required this.lat,
    required this.lng,
    required this.kind,
    this.label,
    this.number,
    this.id,
  });

  final double lat;
  final double lng;
  final OtwMarkerKind kind;
  final String? label;
  final int? number;

  /// Id bebas (misalnya id tempat), dikirim balik lewat [OtwMap.onPointTap].
  final String? id;
}

/// Titik kamera yang diminta dari luar (tombol lokasi saya, hasil pencarian).
/// [OtwMap] pindah setiap kali objek fokus baru (bukan sama) diberikan.
class OtwMapFocus {
  const OtwMapFocus(this.lat, this.lng, {this.zoom = 16});

  final double lat;
  final double lng;
  final double zoom;
}

/// Peta asli (tile OpenStreetMap) dengan penanda bergaya OTWEY.
///
/// Kamera otomatis memuat semua [points]. Kalau [points] kosong, peta berpusat
/// di [center]. [showRoute] menyambung titik sesuai urutan dengan garis putus.
/// TODO(hadi): garis rute masih lurus antar titik; ganti dengan geometri jalan
/// dari cache_travel_time setelah prekomputasi rute tersedia.
class OtwMap extends StatefulWidget {
  const OtwMap({
    required this.points,
    this.center,
    this.height,
    this.showRoute = false,
    this.interactive = true,
    this.refitOnChange = true,
    this.onTap,
    this.onPointTap,
    this.selectedId,
    this.maxMarkers,
    this.me,
    this.focus,
    this.fitPadding = const EdgeInsets.all(56),
    this.attributionInset = EdgeInsets.zero,
    super.key,
  });

  /// Jarak atribusi OSM dari tepi peta, untuk peta yang bagian bawahnya
  /// tertutup lembar bawah. Atribusi wajib terlihat (lisensi ODbL).
  final EdgeInsets attributionInset;

  final List<OtwMapPoint> points;

  /// Pusat peta saat [points] kosong.
  final ({double lat, double lng})? center;

  /// Tinggi peta. Null berarti mengikuti ukuran induk.
  final double? height;
  final bool showRoute;
  final bool interactive;

  /// Pasang ulang kamera saat titik berubah. Matikan untuk peta pemilih titik.
  final bool refitOnChange;

  /// Dipanggil saat peta diketuk, dengan koordinat ketukan.
  final void Function(double lat, double lng)? onTap;

  /// Dipanggil saat penanda diketuk.
  final ValueChanged<OtwMapPoint>? onPointTap;

  /// Penanda dengan [OtwMapPoint.id] ini tampil lebih besar.
  final String? selectedId;

  /// Batas jumlah penanda yang digambar. Null berarti semua. Penanda
  /// [selectedId] selalu ikut tampil dan urutannya tidak memengaruhi kamera.
  final int? maxMarkers;

  /// Posisi user (titik biru).
  final ({double lat, double lng})? me;

  /// Pindahkan kamera ke titik ini setiap kali objeknya berganti.
  final OtwMapFocus? focus;
  final EdgeInsets fitPadding;

  @override
  State<OtwMap> createState() => _OtwMapState();
}

class _OtwMapState extends State<OtwMap> {
  static const _singleZoom = 16.0;
  static const _cityZoom = 13.0;
  static const _maxFitZoom = 17.0;

  final _controller = MapController();
  bool _ready = false;
  Size? _lastSize;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = animation?..addStatusListener(_onRouteStatus);
  }

  /// Tile bisa dihitung saat halaman masih dalam animasi transisi, sehingga
  /// tepi peta kosong. Setelah transisi selesai, paksa muat ulang tile.
  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _nudge();
  }

  /// Geser zoom sangat sedikit. Kamera yang benar benar berubah memicu
  /// TileLayer menghitung ulang tile yang terlihat dari ukuran peta terbaru.
  void _nudge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) return;
      final cam = _controller.camera;
      _controller.move(cam.center, cam.zoom + 0.0001);
    });
  }

  void _onSize(Size size) {
    if (_lastSize == size) return;
    final first = _lastSize == null;
    _lastSize = size;
    if (first) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) return;
      if (widget.refitOnChange) _fit();
      _nudge();
    });
  }

  List<LatLng> get _coords => [
        for (final p in widget.points) LatLng(p.lat, p.lng),
      ];

  void _fit() {
    final coords = _coords;
    if (coords.length >= 2) {
      _controller.fitCamera(
        CameraFit.coordinates(coordinates: coords, padding: widget.fitPadding, maxZoom: _maxFitZoom),
      );
    } else if (coords.length == 1) {
      _controller.move(coords.first, _singleZoom);
    }
  }

  @override
  void didUpdateWidget(OtwMap old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    final f = widget.focus;
    if (f != null && !identical(f, old.focus)) {
      _controller.move(LatLng(f.lat, f.lng), f.zoom);
      return;
    }
    if (widget.refitOnChange && !_sameCoords(old.points, widget.points)) _fit();
  }

  bool _sameCoords(List<OtwMapPoint> a, List<OtwMapPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].lat != b[i].lat || a[i].lng != b[i].lng) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final coords = _coords;
    final fallback = widget.center ?? AppConfig.cityCenters.values.first;
    final focus = widget.focus;

    final options = MapOptions(
      initialCameraFit: focus == null && coords.length >= 2
          ? CameraFit.coordinates(coordinates: coords, padding: widget.fitPadding, maxZoom: _maxFitZoom)
          : null,
      initialCenter: focus != null
          ? LatLng(focus.lat, focus.lng)
          : coords.length == 1
              ? coords.first
              : LatLng(fallback.lat, fallback.lng),
      initialZoom: focus?.zoom ?? (coords.length == 1 ? _singleZoom : _cityZoom),
      backgroundColor: c.surface300,
      interactionOptions: InteractionOptions(
        flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
      ),
      onMapReady: () {
        _ready = true;
        _nudge();
      },
      onTap: widget.onTap == null ? null : (_, p) => widget.onTap!(p.latitude, p.longitude),
    );

    final me = widget.me;
    final map = FlutterMap(
      mapController: _controller,
      options: options,
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: AppConfig.mapUserAgentPackage,
          maxNativeZoom: 19,
          // Muat tile sedikit di luar layar, supaya tepi peta tidak kosong saat
          // ukuran peta berubah (transisi halaman, lembar bawah ditarik).
          panBuffer: 2,
          // Tanpa animasi fade-in: tile yang selesai dimuat saat transisi
          // halaman tidak tergambar sampai peta disentuh.
          tileDisplay: const TileDisplay.instantaneous(),
          tileBuilder: dark ? darkModeTileBuilder : null,
        ),
        if (widget.showRoute && coords.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: coords,
                color: c.brand,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                pattern: StrokePattern.dashed(segments: const [10, 7]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (me != null)
              Marker(
                point: LatLng(me.lat, me.lng),
                width: OtwMapMarkerView.size,
                height: OtwMapMarkerView.size,
                child: const OtwMapMarkerView(kind: OtwMarkerKind.me),
              ),
            for (final p in _markerPoints) _marker(p),
          ],
        ),
        _Attribution(inset: widget.attributionInset),
      ],
    );

    // Lebar dipaksa penuh: di dalam Stack tanpa batas ketat, FlutterMap
    // bisa mengukur lebar lebih kecil dari area yang terlihat.
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          _onSize(box.biggest);
          return map;
        },
      ),
    );
  }

  /// Titik yang digambar sebagai penanda, dipotong sesuai [OtwMap.maxMarkers].
  List<OtwMapPoint> get _markerPoints {
    final max = widget.maxMarkers;
    if (max == null || widget.points.length <= max) return widget.points;
    final selected = widget.selectedId;
    final shown = <OtwMapPoint>[];
    for (final p in widget.points) {
      if (p.id != null && p.id == selected) shown.add(p);
    }
    for (final p in widget.points) {
      if (shown.length >= max) break;
      if (p.id != null && p.id == selected) continue;
      shown.add(p);
    }
    return shown;
  }

  Marker _marker(OtwMapPoint p) {
    final selected = p.id != null && p.id == widget.selectedId;
    final scale = selected ? 1.35 : 1.0;
    final size = OtwMapMarkerView.size * scale;
    Widget child = OtwMapMarkerView(kind: p.kind, number: p.number, label: p.label);
    if (selected) child = Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child);
    final onTap = widget.onPointTap;
    if (onTap != null) {
      child = Semantics(
        button: true,
        label: p.label,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => onTap(p), child: child),
      );
    }
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: size,
      height: size,
      // Pin menunjuk ke titik dengan ujung bawahnya, penanda lain berpusat di titik.
      alignment: p.kind == OtwMarkerKind.place ? Alignment.topCenter : Alignment.center,
      child: child,
    );
  }
}

/// Atribusi OSM ringkas di pojok kanan bawah (wajib tampil, lisensi ODbL).
class _Attribution extends StatelessWidget {
  const _Attribution({required this.inset});

  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: inset + const EdgeInsets.all(6),
        child: Semantics(
          label: AppCopy.mapAttribution,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.surface200.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppCopy.mapAttributionShort,
              style: TextStyle(fontSize: 9.5, color: c.inkMuted, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
