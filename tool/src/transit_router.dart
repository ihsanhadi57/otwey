/// Pencari rute transum offline berbasis frekuensi (bukan jadwal per menit).
///
/// Jaringan = halte + pola (urutan halte satu jalur satu arah, dengan menit
/// kumulatif dan headway). Biaya naik = setengah headway (rata rata menunggu).
/// Dijkstra di atas state (halte | di dalam kendaraan) dengan batas naik
/// [maxBoardings]. Deterministik: urutan tie-break tetap.
library;

import 'dart:math' as math;

/// Moda satu jalur. Nilai string dipakai di file hasil.
enum RideMode {
  bus('bus'),
  brt('brt'),
  mrt('mrt'),
  lrt('lrt'),
  krl('krl');

  const RideMode(this.code);
  final String code;

  static RideMode fromCode(String c) => values.firstWhere((m) => m.code == c);
}

class TransitStop {
  const TransitStop(this.id, this.name, this.lat, this.lng);

  final String id;
  final String name;
  final double lat;
  final double lng;
}

/// Tarif satu jalur: dasar untuk [baseKm] pertama, lalu per km, dibatasi [max].
/// Bus TransJakarta: tarif datar (perKm 0).
class Fare {
  const Fare({required this.base, this.baseKm = 0, this.perKm = 0, this.max});

  final int base;
  final double baseKm;
  final int perKm;
  final int? max;

  int of(double km) {
    final extra = km > baseKm ? ((km - baseKm) * perKm).ceil() : 0;
    final v = base + extra;
    return max == null ? v : math.min(v, max!);
  }
}

class TransitLine {
  const TransitLine({
    required this.key,
    required this.name,
    required this.short,
    required this.mode,
    required this.fare,
    this.color,
    this.fareGroup,
  });

  final String key;
  final String name;
  final String short;
  final RideMode mode;
  final Fare fare;

  /// "RRGGBB" tanpa '#'.
  final String? color;

  /// Jalur dengan grup sama berbagi satu tarif per perjalanan (integrasi
  /// TransJakarta: pindah bus tidak bayar lagi).
  final String? fareGroup;
}

/// Satu pola: [stops] berurutan, [minutes] kumulatif dari halte pertama.
class TransitPattern {
  TransitPattern({
    required this.line,
    required this.stops,
    required this.minutes,
    required this.headway,
  }) : assert(stops.length == minutes.length && stops.length >= 2);

  final TransitLine line;
  final List<int> stops;
  final List<double> minutes;

  /// Menit antar kedatangan.
  final double headway;
}

/// Satu langkah hasil.
class RouteLeg {
  RouteLeg.walk({required this.fromName, required this.toName, required this.minutes})
      : line = null,
        stops = 0,
        km = 0,
        wait = 0;

  RouteLeg.ride({
    required TransitLine this.line,
    required this.fromName,
    required this.toName,
    required this.minutes,
    required this.stops,
    required this.km,
    required this.wait,
  });

  final TransitLine? line;
  final String fromName;
  final String toName;

  /// Menit di kendaraan, atau menit jalan kaki.
  final double minutes;
  final int stops;
  final double km;

  /// Perkiraan menunggu sebelum naik.
  final double wait;

  bool get isWalk => line == null;
}

class FoundRoute {
  FoundRoute(this.legs);

  final List<RouteLeg> legs;

  double get minutes => legs.fold(0.0, (a, l) => a + l.minutes + l.wait);

  int get rides => legs.where((l) => !l.isWalk).length;

  int get fare {
    var total = 0;
    final paidGroups = <String>{};
    for (final l in legs) {
      final line = l.line;
      if (line == null) continue;
      final g = line.fareGroup;
      if (g != null) {
        if (paidGroups.add(g)) total += line.fare.of(l.km);
      } else {
        total += line.fare.of(l.km);
      }
    }
    return total;
  }
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class RouterConfig {
  const RouterConfig({
    this.walkKmh = 4.5,
    this.roadFactor = 1.3,
    this.maxAccessKm = 0.9,
    this.maxTransferKm = 0.4,
    this.maxWaitMinutes = 15,
    this.boardPenalty = 4,
    this.maxBoardings = 3,
  });

  final double walkKmh;

  /// Jarak jalan = garis lurus × faktor ini.
  final double roadFactor;

  /// Jalan kaki terjauh dari titik asal ke halte, dan dari halte ke tujuan.
  final double maxAccessKm;

  /// Jalan kaki terjauh antar halte saat pindah.
  final double maxTransferKm;

  /// Batas rata rata menunggu (headway panjang dianggap terjadwal).
  final double maxWaitMinutes;

  /// Penalti per naik, hanya untuk memilih rute (tidak masuk menit hasil).
  final double boardPenalty;
  final int maxBoardings;

  double walkMinutes(double km) => km * roadFactor / walkKmh * 60;
}

class TransitRouter {
  TransitRouter(
    this.stops,
    this.patterns, {
    this.config = const RouterConfig(),
    this.extraTransfers = const [],
  }) {
    _buildIndex();
  }

  /// Pindah jalan kaki tambahan (dari, ke, menit), misalnya antar stasiun rel
  /// yang lebih jauh dari [RouterConfig.maxTransferKm].
  final List<(int, int, double)> extraTransfers;

  final List<TransitStop> stops;
  final List<TransitPattern> patterns;
  final RouterConfig config;

  /// Per halte: (pola, posisi) yang lewat.
  late final List<List<(int, int)>> _servedBy;

  /// Per halte: halte lain yang bisa dicapai jalan kaki (indeks, menit).
  late final List<List<(int, double)>> _walks;

  late final _Grid _grid;

  /// Offset state "di dalam kendaraan": setiap (pola, posisi) dapat nomor unik.
  late final List<int> _patternBase;
  late final int _onboardCount;

  void _buildIndex() {
    _servedBy = List.generate(stops.length, (_) => <(int, int)>[]);
    _patternBase = [];
    var n = 0;
    for (var p = 0; p < patterns.length; p++) {
      _patternBase.add(n);
      final ps = patterns[p].stops;
      for (var i = 0; i < ps.length; i++) {
        _servedBy[ps[i]].add((p, i));
      }
      n += ps.length;
    }
    _onboardCount = n;
    _grid = _Grid(stops, cellKm: config.maxTransferKm);
    _walks = List.generate(stops.length, (s) {
      final out = <(int, double)>[];
      if (_servedBy[s].isEmpty) return out;
      for (final t in _grid.near(stops[s].lat, stops[s].lng, config.maxTransferKm)) {
        if (t == s || _servedBy[t].isEmpty) continue;
        final km = haversineKm(stops[s].lat, stops[s].lng, stops[t].lat, stops[t].lng);
        out.add((t, config.walkMinutes(km)));
      }
      return out;
    });
    for (final (a, b, m) in extraTransfers) {
      if (!_walks[a].any((w) => w.$1 == b)) _walks[a].add((b, m));
    }
  }

  /// Halte dalam jangkauan jalan kaki dari titik, dengan menit jalan.
  List<(int, double)> _access(double lat, double lng) {
    final out = <(int, double)>[];
    for (final s in _grid.near(lat, lng, config.maxAccessKm)) {
      if (_servedBy[s].isEmpty) continue;
      final km = haversineKm(lat, lng, stops[s].lat, stops[s].lng);
      out.add((s, config.walkMinutes(km)));
    }
    return out;
  }

  /// Satu pencarian dari titik asal ke banyak tujuan sekaligus. Hasil sejajar
  /// dengan [targets]; null kalau tidak ada rute dengan minimal satu kali naik.
  List<FoundRoute?> routeMany(
    ({double lat, double lng, String name}) origin,
    List<({double lat, double lng, String name})> targets,
  ) {
    final k = config.maxBoardings + 1;
    final stateCount = (stops.length + _onboardCount) * k;
    final cost = List<double>.filled(stateCount, double.infinity);
    final parent = List<int>.filled(stateCount, -1);
    // Jenis tepi ke state ini: 0 asal-jalan, 1 jalan antar halte, 2 naik, 3 jalan di kendaraan, 4 turun.
    final via = List<int>.filled(stateCount, -1);
    final heap = _Heap();

    int stopState(int s, int b) => s * k + b;
    int boardState(int p, int i, int b) => (stops.length + _patternBase[p] + i) * k + b;

    void relax(int state, double c, int from, int kind) {
      if (c < cost[state] - 1e-9) {
        cost[state] = c;
        parent[state] = from;
        via[state] = kind;
        heap.push(c, state);
      }
    }

    for (final (s, m) in _access(origin.lat, origin.lng)) {
      relax(stopState(s, 0), m, -1, 0);
    }

    while (heap.isNotEmpty) {
      final (c, state) = heap.pop();
      if (c > cost[state] + 1e-9) continue;
      final b = state % k;
      final node = state ~/ k;
      if (node < stops.length) {
        final s = node;
        // Jalan ke halte terdekat lain, hanya setelah turun (b > 0) supaya
        // jalan awal tetap satu langkah dari titik asal.
        if (b > 0) {
          for (final (t, m) in _walks[s]) {
            if (via[state] == 1) break; // tidak jalan dua kali berturut turut
            relax(stopState(t, b), c + m, state, 1);
          }
        }
        if (b < config.maxBoardings) {
          for (final (p, i) in _servedBy[s]) {
            if (i == patterns[p].stops.length - 1) continue;
            final wait = math.min(patterns[p].headway / 2, config.maxWaitMinutes);
            relax(boardState(p, i, b + 1), c + wait + config.boardPenalty, state, 2);
          }
        }
      } else {
        final flat = node - stops.length;
        final p = _patternOf(flat);
        final i = flat - _patternBase[p];
        final pat = patterns[p];
        if (i + 1 < pat.stops.length) {
          relax(boardState(p, i + 1, b), c + (pat.minutes[i + 1] - pat.minutes[i]), state, 3);
        }
        if (via[state] == 3) {
          relax(stopState(pat.stops[i], b), c, state, 4);
        }
      }
    }

    return [
      for (final t in targets) _bestTo(t, cost, parent, via, k, origin),
    ];
  }

  FoundRoute? _bestTo(
    ({double lat, double lng, String name}) t,
    List<double> cost,
    List<int> parent,
    List<int> via,
    int k,
    ({double lat, double lng, String name}) origin,
  ) {
    var best = double.infinity;
    var bestState = -1;
    var bestEgress = 0.0;
    for (final (s, m) in _access(t.lat, t.lng)) {
      for (var b = 1; b < k; b++) {
        final st = s * k + b;
        final total = cost[st] + m;
        if (total < best - 1e-9 || (total < best + 1e-9 && st < bestState)) {
          best = total;
          bestState = st;
          bestEgress = m;
        }
      }
    }
    if (bestState < 0) return null;
    return _rebuild(bestState, bestEgress, parent, via, cost, k, origin.name, t.name);
  }

  FoundRoute _rebuild(
    int end,
    double egress,
    List<int> parent,
    List<int> via,
    List<double> cost,
    int k,
    String originName,
    String targetName,
  ) {
    final chain = <int>[];
    for (var s = end; s >= 0; s = parent[s]) {
      chain.add(s);
    }
    final states = chain.reversed.toList();
    final legs = <RouteLeg>[];
    String nameOf(int state) => stops[state ~/ k].name;

    // Jalan dari titik asal ke halte pertama.
    final first = states.first;
    legs.add(RouteLeg.walk(fromName: originName, toName: nameOf(first), minutes: cost[first]));

    var i = 1;
    while (i < states.length) {
      final kind = via[states[i]];
      if (kind == 1) {
        final a = states[i - 1];
        final b = states[i];
        legs.add(RouteLeg.walk(fromName: nameOf(a), toName: nameOf(b), minutes: cost[b] - cost[a]));
        i++;
      } else if (kind == 2) {
        final boardFrom = states[i - 1];
        final flat0 = states[i] ~/ k - stops.length;
        final p = _patternOf(flat0);
        final pos0 = flat0 - _patternBase[p];
        var j = i;
        while (j + 1 < states.length && via[states[j + 1]] == 3) {
          j++;
        }
        final pos1 = states[j] ~/ k - stops.length - _patternBase[p];
        final pat = patterns[p];
        var km = 0.0;
        for (var q = pos0; q < pos1; q++) {
          final a = stops[pat.stops[q]];
          final b = stops[pat.stops[q + 1]];
          km += haversineKm(a.lat, a.lng, b.lat, b.lng);
        }
        legs.add(RouteLeg.ride(
          line: pat.line,
          fromName: nameOf(boardFrom),
          toName: stops[pat.stops[pos1]].name,
          minutes: pat.minutes[pos1] - pat.minutes[pos0],
          stops: pos1 - pos0,
          km: km,
          wait: math.min(pat.headway / 2, config.maxWaitMinutes),
        ));
        i = j + 2; // lewati state turun
      } else {
        i++;
      }
    }
    legs.add(RouteLeg.walk(fromName: legs.last.toName, toName: targetName, minutes: egress));
    return FoundRoute(_mergeWalks(legs));
  }

  /// Gabung jalan kaki berurutan. Jalan sangat pendek dibuang hanya kalau
  /// asal dan tujuannya sama; pindah antar halte bernama beda tetap ditulis
  /// (minimal 1 menit) supaya langkahnya nyambung.
  List<RouteLeg> _mergeWalks(List<RouteLeg> legs) {
    final out = <RouteLeg>[];
    for (final l in legs) {
      if (l.isWalk && l.fromName == l.toName) continue;
      if (l.isWalk && out.isNotEmpty && out.last.isWalk) {
        final prev = out.removeLast();
        out.add(RouteLeg.walk(fromName: prev.fromName, toName: l.toName, minutes: prev.minutes + l.minutes));
      } else {
        out.add(l);
      }
    }
    return [
      for (final l in out)
        if (l.isWalk && l.minutes < 1)
          RouteLeg.walk(fromName: l.fromName, toName: l.toName, minutes: 1)
        else
          l,
    ];
  }

  int _patternOf(int flat) {
    var lo = 0;
    var hi = _patternBase.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_patternBase[mid] <= flat) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// Grid sederhana untuk mencari halte terdekat.
class _Grid {
  _Grid(this.stops, {required double cellKm}) : _cell = cellKm / 111 {
    for (var i = 0; i < stops.length; i++) {
      _cells.putIfAbsent(_key(stops[i].lat, stops[i].lng), () => []).add(i);
    }
  }

  final List<TransitStop> stops;
  final double _cell;
  final _cells = <(int, int), List<int>>{};

  (int, int) _key(double lat, double lng) => ((lat / _cell).floor(), (lng / _cell).floor());

  Iterable<int> near(double lat, double lng, double km) sync* {
    final r = (km / 111 / _cell).ceil();
    final (cy, cx) = _key(lat, lng);
    for (var y = cy - r; y <= cy + r; y++) {
      for (var x = cx - r; x <= cx + r; x++) {
        for (final i in _cells[(y, x)] ?? const <int>[]) {
          if (haversineKm(lat, lng, stops[i].lat, stops[i].lng) <= km) yield i;
        }
      }
    }
  }
}

/// Min-heap biner (biaya, state).
class _Heap {
  final _c = <double>[];
  final _s = <int>[];

  bool get isNotEmpty => _c.isNotEmpty;

  void push(double c, int s) {
    _c.add(c);
    _s.add(s);
    var i = _c.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_less(i, p)) {
        _swap(i, p);
        i = p;
      } else {
        break;
      }
    }
  }

  (double, int) pop() {
    final top = (_c.first, _s.first);
    final lastC = _c.removeLast();
    final lastS = _s.removeLast();
    if (_c.isNotEmpty) {
      _c[0] = lastC;
      _s[0] = lastS;
      var i = 0;
      while (true) {
        final l = 2 * i + 1;
        final r = l + 1;
        var m = i;
        if (l < _c.length && _less(l, m)) m = l;
        if (r < _c.length && _less(r, m)) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  bool _less(int a, int b) => _c[a] < _c[b] || (_c[a] == _c[b] && _s[a] < _s[b]);

  void _swap(int a, int b) {
    final tc = _c[a];
    _c[a] = _c[b];
    _c[b] = tc;
    final ts = _s[a];
    _s[a] = _s[b];
    _s[b] = ts;
  }
}
