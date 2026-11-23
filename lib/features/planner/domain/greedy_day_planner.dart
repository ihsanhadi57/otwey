import '../../../core/copy/app_copy.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/geo.dart';
import '../../places/domain/place.dart';
import '../../trip_setup/domain/plan_pin.dart';
import '../../trip_setup/domain/travel_mode.dart';
import '../../trip_setup/domain/trip_draft.dart';
import '../../trip_setup/domain/vibe_catalog.dart';
import 'access_route.dart';
import 'city_transit.dart';
import 'day_planner.dart';
import 'fare_rule.dart';
import 'itinerary.dart';
import 'leg_mode.dart';
import 'plan_item.dart';
import 'planner_config.dart';
import 'schedule.dart';

/// Planner greedy deterministik (PRD 8.2). Murni Dart, tanpa I/O.
///
/// Urutan: pilih cara naik dan turun kereta (stasiun Whoosh langsung atau
/// lewat KA Feeder), jendela waktu, kereta pergi/pulang, kunci tujuan jam
/// tetap, sisip tujuan bebas jam urut prioritas, isi celah dengan kandidat
/// tempat, validasi, lalu status. Setiap cara akses dicoba lengkap, lalu
/// dipilih yang paling banyak memberi waktu di kota tujuan.
class GreedyDayPlanner implements DayPlanner {
  const GreedyDayPlanner();

  @override
  PlanResult build(PlannerInput input) {
    final options = _accessOptions(input);
    if (options.isEmpty) return const PlanResult(status: PlanStatus.impossible, items: []);
    _Run? best;
    PlanResult? bestResult;
    PlanResult? firstImpossible;
    for (final a in options) {
      final run = _Run(input, a);
      final result = run.build();
      if (result.itinerary == null) {
        firstImpossible ??= result;
        if (result.blockingPinId != null && firstImpossible.blockingPinId == null) firstImpossible = result;
        continue;
      }
      if (best == null || run.betterThan(best)) {
        best = run;
        bestResult = result;
      }
    }
    return bestResult ?? firstImpossible!;
  }
}

/// Cara naik/turun kereta cepat di satu sisi kota.
///
/// [station] = stasiun Whoosh. [hub] = stasiun KA Feeder di kota (misalnya
/// Stasiun Bandung) kalau user naik/turun lewat feeder, null kalau langsung.
class _Side {
  const _Side(this.station, [this.hub]);
  final String station;
  final String? hub;

  /// Titik yang didatangi/ditinggalkan user di kota: hub feeder atau stasiun Whoosh.
  String get point => hub ?? station;
}

class _Access {
  const _Access(this.origin, this.dest);
  final _Side origin;
  final _Side dest;
}

/// Semua kombinasi stasiun di kota asal dan kota tujuan yang dilewati kereta,
/// langsung atau lewat KA Feeder yang tersambung ke stasiun itu.
List<_Access> _accessOptions(PlannerInput input) {
  if (input.outboundTrips.isEmpty || input.returnTrips.isEmpty) return const [];
  String? cityOf(String code) {
    for (final s in input.stations) {
      if (s.code == code) return s.city;
    }
    return null;
  }

  List<_Side> sides(String city) {
    final codes = <String>{
      for (final t in input.outboundTrips)
        for (final s in t.stops)
          if (cityOf(s.stationCode) == city) s.stationCode,
    };
    final out = <_Side>[];
    for (final code in codes.toList()..sort()) {
      out.add(_Side(code));
      final hubs = <String>{
        for (final f in input.feeders)
          if (f.originStationCode == code && cityOf(f.destinationStationCode) == city) f.destinationStationCode,
      };
      for (final h in hubs.toList()..sort()) {
        out.add(_Side(code, h));
      }
    }
    return out;
  }

  final origins = sides(input.draft.originCity);
  final dests = sides(input.draft.destinationCity);
  return [
    for (final o in origins)
      for (final d in dests) _Access(o, d),
  ];
}

/// Faktor jarak garis lurus ke jarak jalan (PRD 8.4 fallback perkiraan).
const _roadFactor = 1.4;

/// Kecepatan jalan kaki untuk estimasi (km/jam).
const _walkKmh = 5.0;

/// Kategori makan besar, diutamakan di jam makan.
const _mealCategories = {'makanan_berat', 'makanan_barat'};

/// Jam makan siang dan malam (menit sejak tengah malam).
const _mealWindows = [(11 * 60, 13 * 60 + 30), (17 * 60 + 30, 20 * 60)];

/// Bobot skor kandidat dalam satuan menit tempuh. Skor kecil = lebih baik.
const _repeatCategoryPenalty = 20;
const _mealBonus = 20;
const _offMealPenalty = 30;

/// Jarak minimal antar dua makan besar (menit).
const _mealGapMinutes = 180;

class _Node {
  const _Node(this.time, this.lat, this.lng, this.label);
  final int time;
  final double lat;
  final double lng;
  final String label;
}

class _Visit {
  _Visit({
    required this.lat,
    required this.lng,
    required this.label,
    required this.minutes,
    this.start,
    this.end,
    this.placeId,
    this.pinId,
    this.locked = false,
    this.optional = false,
    this.categoryCode = '',
    this.categoryLabel = '',
    this.reason,
    this.place,
  });
  final double lat;
  final double lng;
  final String label;
  final int minutes;
  int? start;
  int? end;
  final String? placeId;
  final String? pinId;
  final bool locked;
  final bool optional;
  final String categoryCode;
  final String categoryLabel;
  String? reason;
  final Place? place;
}

/// Kereta pergi beserta feeder di kedua ujungnya.
class _Outbound {
  const _Outbound(this.trip, this.dep, this.arr, this.atBoard, this.hubArrival, this.originFeeder, this.destFeeder);
  final WhooshTrip trip;
  final int dep;
  final int arr;

  /// Jam paling lambat user tiba di titik naik (stasiun Whoosh atau hub feeder).
  final int atBoard;

  /// Jam tiba di titik turun di kota tujuan.
  final int hubArrival;
  final FeederDeparture? originFeeder;
  final FeederDeparture? destFeeder;
}

/// Kereta pulang beserta feeder di kedua ujungnya.
class _Return {
  const _Return(this.trip, this.dep, this.arr, this.deadline, this.cityFeeder, this.homeFeeder, this.arrivalAtPoint);
  final WhooshTrip trip;
  final int dep;
  final int arr;

  /// Jam paling lambat user tiba di titik naik di kota tujuan.
  final int deadline;
  final FeederDeparture? cityFeeder;
  final FeederDeparture? homeFeeder;

  /// Jam tiba di titik turun di kota asal.
  final int arrivalAtPoint;
}

class _Run {
  _Run(this.input, this.access, {this.probeEarlierReturn = true});

  final PlannerInput input;
  final _Access access;

  /// False untuk run percobaan di dalam [_earlierReturn], supaya tidak berulang.
  final bool probeEarlierReturn;
  bool _moreAvailable = false;
  PlannerConfig get config => input.config;

  final List<_Visit> _visits = [];
  final List<String> _dropped = [];
  final List<String> _droppedKept = [];
  final List<TimelineEntry> _entries = [];
  final List<PlanItem> _items = [];
  final List<RoutePoint> _route = [];
  int _legCounter = 0;
  int _stopNumber = 0;
  int _clock = 0;

  late _Node _hub;
  late _Node _return;
  late double _originLat;
  late double _originLng;
  late String _originLabel;
  late bool _hasOrigin;
  late _Outbound _out;
  late _Return _ret;
  int _homeArrival = 0;
  int _cityMinutes = 0;

  /// Urutan pilihan antar cara akses: tujuan user lebih banyak masuk, tempat
  /// lebih banyak, waktu bersih di kota lebih lama, lalu tiba di rumah lebih awal.
  bool betterThan(_Run other) {
    if (_dropped.length != other._dropped.length) return _dropped.length < other._dropped.length;
    if (_visits.length != other._visits.length) return _visits.length > other._visits.length;
    if (_cityMinutes != other._cityMinutes) return _cityMinutes > other._cityMinutes;
    return _homeArrival < other._homeArrival;
  }

  PlanResult build() {
    final origin = input.draft.origin;
    _hasOrigin = origin != null || (input.draft.originLat != null && input.draft.originLng != null);
    final boardPoint = _station(access.origin.point);
    _originLat = origin?.lat ?? input.draft.originLat ?? boardPoint?.lat ?? 0;
    _originLng = origin?.lng ?? input.draft.originLng ?? boardPoint?.lng ?? 0;
    _originLabel = origin?.label ?? input.draft.originLabel ?? boardPoint?.name ?? 'Rumah';

    final travelToBoard = _travelToCode(access.origin.point);
    final readyAtBoard = input.draft.earliestDeparture + travelToBoard;

    final fixedPins = input.draft.pins.where((p) => p.isFixedTime).toList()
      ..sort((a, b) => a.fixedStart!.compareTo(b.fixedStart!));
    final firstFixed = fixedPins.isEmpty ? null : fixedPins.first;

    final out = _pickOutbound(readyAtBoard, firstFixed);
    if (out == null) {
      return PlanResult(
        status: PlanStatus.impossible,
        items: const [],
        blockingPinId: firstFixed?.priority == PinPriority.wajib ? firstFixed?.id : null,
      );
    }
    _out = out;
    final hubStation = _station(access.dest.point);
    _hub = _Node(out.hubArrival + config.bufferAfterTrain, hubStation?.lat ?? 0, hubStation?.lng ?? 0,
        hubStation?.name ?? access.dest.point);

    final travelHome = _travelToCode(access.origin.point, home: true);
    final cap = input.draft.returnDepartureCap;
    final ret = (cap == null ? null : _pickReturn(travelHome, cap: cap)) ?? _pickReturn(travelHome);
    if (ret == null) {
      return const PlanResult(status: PlanStatus.impossible, items: []);
    }
    _ret = ret;
    _return = _Node(ret.deadline, hubStation?.lat ?? 0, hubStation?.lng ?? 0, hubStation?.name ?? access.dest.point);

    for (final pin in fixedPins) {
      final visit = _pinVisit(pin, locked: true);
      if (!_tryInsert(visit)) {
        if (pin.priority == PinPriority.wajib) {
          return PlanResult(status: PlanStatus.impossible, items: const [], blockingPinId: pin.id);
        }
        _dropped.add(pin.id);
      }
    }

    final flexible = input.draft.pins.where((p) => !p.isFixedTime).toList()
      ..sort((a, b) => a.priority.rank.compareTo(b.priority.rank));
    for (final pin in flexible) {
      final visit = _pinVisit(pin, locked: false);
      if (!_tryInsert(visit)) _dropped.add(pin.id);
    }

    _insertKept();
    _fillCandidates();

    if (!_validate()) {
      return const PlanResult(status: PlanStatus.impossible, items: []);
    }

    _render(travelToBoard, travelHome);

    _homeArrival = ret.arrivalAtPoint + travelHome;
    final center = _center(firstFixed);
    _cityMinutes = _return.time -
        _hub.time -
        _travelXY(_hub.lat, _hub.lng, center.$1, center.$2) -
        _travelXY(center.$1, center.$2, _return.lat, _return.lng);
    final spare = input.draft.latestReturn - _homeArrival;
    final status = spare >= config.warningThreshold ? PlanStatus.safe : PlanStatus.tight;
    final fixedMinutes = _visits.where((v) => v.locked).fold(0, (s, v) => s + v.minutes);
    final freeMinutes = (_return.time - _hub.time - fixedMinutes).clamp(0, 1 << 31).toInt();
    final pinNames = {for (final p in input.draft.pins) p.id: p.name};

    return PlanResult(
      status: status,
      items: _items,
      droppedPinIds: _dropped,
      freeMinutes: freeMinutes,
      minutesUntilLeave: status == PlanStatus.tight ? spare : null,
      itinerary: Itinerary(
        originCity: input.draft.originCity,
        destinationCity: input.draft.destinationCity,
        originLabel: _originLabel,
        date: input.draft.travelDate,
        vibeLabel: input.draft.vibe.label,
        budgetLabel: _budgetLabel(input.draft.budget),
        entries: _entries,
        freeMinutes: freeMinutes,
        latestReturn: input.draft.latestReturn,
        status: status,
        route: _route,
        returnDeparture: ret.dep,
        earlierReturnDeparture: probeEarlierReturn ? _earlierReturn(ret.dep) : null,
        moreStopsAvailable: _moreAvailable,
        droppedPlaceNames: _droppedKept,
        droppedPinNames: [for (final id in _dropped) pinNames[id] ?? id],
      ),
    );
  }

  /// Titik tengah aktivitas di kota tujuan: tujuan jam tetap pertama, atau
  /// rata rata kandidat tempat, atau titik turun kereta.
  (double, double) _center(PlanPin? firstFixed) {
    if (firstFixed != null) return (firstFixed.lat, firstFixed.lng);
    final places = input.candidatePlaces;
    if (places.isEmpty) return (_hub.lat, _hub.lng);
    final lat = places.fold(0.0, (s, p) => s + p.lat) / places.length;
    final lng = places.fold(0.0, (s, p) => s + p.lng) / places.length;
    return (lat, lng);
  }

  // ---------------------------------------------------------------------------
  // Kereta dan feeder

  FeederDeparture? _feeder(int tripId, String from, String to) {
    for (final f in input.feeders) {
      if (f.connectsTripId == tripId && f.originStationCode == from && f.destinationStationCode == to) return f;
    }
    return null;
  }

  /// Feeder [from] → [to] yang tiba paling akhir tapi masih sebelum [arriveBy].
  FeederDeparture? _latestFeederBefore(String from, String to, int arriveBy) {
    FeederDeparture? best;
    for (final f in input.feeders) {
      if (f.originStationCode != from || f.destinationStationCode != to || f.arrival > arriveBy) continue;
      if (best == null || f.departure > best.departure) best = f;
    }
    return best;
  }

  /// Feeder [from] → [to] paling awal yang berangkat setelah [after].
  FeederDeparture? _firstFeederAfter(String from, String to, int after) {
    FeederDeparture? best;
    for (final f in input.feeders) {
      if (f.originStationCode != from || f.destinationStationCode != to || f.departure < after) continue;
      if (best == null || f.departure < best.departure) best = f;
    }
    return best;
  }

  _Outbound? _outboundOf(WhooshTrip t) {
    final o = access.origin;
    final d = access.dest;
    final dep = t.departureFrom(o.station);
    final arr = t.arrivalAt(d.station);
    if (dep == null || arr == null || arr <= dep) return null;

    FeederDeparture? originFeeder;
    int atBoard;
    if (o.hub == null) {
      atBoard = dep - config.bufferBeforeTrain;
    } else {
      originFeeder = _feeder(t.id, o.hub!, o.station) ??
          _latestFeederBefore(o.hub!, o.station, dep - config.transferMinutes);
      if (originFeeder == null) return null;
      atBoard = originFeeder.departure - config.bufferBeforeFeeder;
    }

    FeederDeparture? destFeeder;
    var hubArrival = arr;
    if (d.hub != null) {
      destFeeder = _feeder(t.id, d.station, d.hub!) ??
          _firstFeederAfter(d.station, d.hub!, arr + config.transferMinutes);
      if (destFeeder == null) return null;
      hubArrival = destFeeder.arrival;
    }
    return _Outbound(t, dep, arr, atBoard, hubArrival, originFeeder, destFeeder);
  }

  /// Kereta pergi: paling awal yang terkejar, atau kalau ada tujuan jam tetap,
  /// paling akhir yang masih tepat waktu (PRD 8.2 langkah 2).
  _Outbound? _pickOutbound(int readyAtBoard, PlanPin? firstFixed) {
    _Outbound? best;
    for (final t in input.outboundTrips) {
      final o = _outboundOf(t);
      if (o == null || o.atBoard < readyAtBoard) continue;
      if (firstFixed != null) {
        final hub = _station(access.dest.point);
        final travel = hub == null ? 0 : _cityTravel(hub.lat ?? firstFixed.lat, hub.lng ?? firstFixed.lng, firstFixed.lat, firstFixed.lng);
        if (o.hubArrival + config.bufferAfterTrain + travel > firstFixed.fixedStart!) continue;
        if (best == null || o.dep > best.dep) best = o;
      } else {
        if (best == null || o.dep < best.dep) best = o;
      }
    }
    return best;
  }

  _Return? _returnOf(WhooshTrip t) {
    final o = access.origin;
    final d = access.dest;
    final dep = t.departureFrom(d.station);
    final arr = t.arrivalAt(o.station);
    if (dep == null || arr == null || arr <= dep) return null;

    FeederDeparture? cityFeeder;
    int deadline;
    if (d.hub == null) {
      deadline = dep - config.bufferBeforeTrain;
    } else {
      cityFeeder = _feeder(t.id, d.hub!, d.station) ??
          _latestFeederBefore(d.hub!, d.station, dep - config.transferMinutes);
      if (cityFeeder == null) return null;
      deadline = cityFeeder.departure - config.bufferBeforeFeeder;
    }

    FeederDeparture? homeFeeder;
    var arrivalAtPoint = arr;
    if (o.hub != null) {
      homeFeeder = _feeder(t.id, o.station, o.hub!) ??
          _firstFeederAfter(o.station, o.hub!, arr + config.transferMinutes);
      if (homeFeeder == null) return null;
      arrivalAtPoint = homeFeeder.arrival;
    }
    return _Return(t, dep, arr, deadline, cityFeeder, homeFeeder, arrivalAtPoint);
  }

  /// Kereta pulang paling akhir yang masih membuat user sampai rumah sebelum
  /// batas (PRD 8.2 langkah 3). [cap] membatasi jam berangkatnya.
  _Return? _pickReturn(int travelHome, {int? cap}) {
    _Return? best;
    for (final t in input.returnTrips) {
      final r = _returnOf(t);
      if (r == null) continue;
      if (cap != null && r.dep > cap) continue;
      if (r.deadline < _hub.time) continue;
      if (r.arrivalAtPoint + config.bufferAfterTrain + travelHome > input.draft.latestReturn) continue;
      if (best == null || r.dep > best.dep) best = r;
    }
    return best;
  }

  /// Kereta pulang paling awal (minimal [PlannerConfig.earlierReturnMinutes]
  /// lebih cepat) yang tetap memuat semua tempat yang sama. Dicek dengan
  /// menjalankan ulang planner, jadi hasilnya pasti bisa dijalani.
  int? _earlierReturn(int retDep) {
    final keys = _placeKeys(_items);
    final recs = [
      for (final v in _visits)
        if (v.pinId == null && v.placeId != null) v.placeId!,
    ];
    final deps = <int>{
      for (final t in input.returnTrips)
        if (t.departureFrom(access.dest.station) case final d? when d <= retDep - config.earlierReturnMinutes) d,
    }.toList()
      ..sort();
    for (final d in deps) {
      final draft = input.draft.copyWith(returnDepartureCap: d, keptPlaceIds: recs, maxStops: recs.length);
      final result = _Run(_withDraft(draft), access, probeEarlierReturn: false).build();
      final it = result.itinerary;
      if (it == null || it.returnDeparture == null || it.returnDeparture! > d) continue;
      if (_sameKeys(_placeKeys(result.items), keys)) return it.returnDeparture;
    }
    return null;
  }

  PlannerInput _withDraft(TripDraft draft) => PlannerInput(
        draft: draft,
        outboundTrips: input.outboundTrips,
        returnTrips: input.returnTrips,
        feeders: input.feeders,
        candidatePlaces: input.candidatePlaces,
        travelMinutes: input.travelMinutes,
        stations: input.stations,
        accessRoutes: input.accessRoutes,
        fareRules: input.fareRules,
        config: input.config,
      );

  static Set<String> _placeKeys(List<PlanItem> items) => {
        for (final i in items)
          if (i.type == PlanItemType.place) i.placeId ?? i.pinId ?? i.title ?? '',
      };

  static bool _sameKeys(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  // ---------------------------------------------------------------------------
  // Kunjungan

  int _stay(String? placeId, String? pinId, int fallback) =>
      input.draft.stayOverrides[placeId ?? ''] ?? input.draft.stayOverrides[pinId ?? ''] ?? fallback;

  _Visit _pinVisit(PlanPin pin, {required bool locked}) {
    final place = pin.placeId == null ? null : _placeById(pin.placeId!);
    final category = place?.categoryCodes.isNotEmpty == true ? place!.categoryCodes.first : pin.purpose.dbValue;
    return _Visit(
      lat: pin.lat,
      lng: pin.lng,
      label: pin.name,
      minutes: locked ? pin.stayMinutes : _stay(pin.placeId, pin.id, pin.stayMinutes),
      start: locked ? pin.fixedStart : null,
      end: locked ? pin.fixedEnd : null,
      placeId: pin.placeId,
      pinId: pin.id,
      locked: locked,
      optional: pin.priority == PinPriority.opsional,
      categoryCode: category,
      categoryLabel: place != null ? _categoryLabel(category) : _purposeLabel(pin.purpose),
      reason: pin.priority == PinPriority.opsional ? AppCopy.priorityOpsional : null,
      place: place,
    );
  }

  List<_Node> _bounds() => [
        _hub,
        for (final v in _visits) ...[
          _Node(v.start!, v.lat, v.lng, v.label),
          _Node(v.end!, v.lat, v.lng, v.label),
        ],
        _return,
      ];

  /// Celah bebas antar kunjungan (bukan di dalam kunjungan terkunci).
  List<({_Node from, _Node to})> _gaps() {
    final gaps = <({_Node from, _Node to})>[];
    var prev = _hub;
    for (final v in _visits) {
      gaps.add((from: prev, to: _Node(v.start!, v.lat, v.lng, v.label)));
      prev = _Node(v.end!, v.lat, v.lng, v.label);
    }
    gaps.add((from: prev, to: _return));
    return gaps;
  }

  /// Sisipkan [v] di celah pertama yang muat. [notBefore] menjaga urutan:
  /// celah yang dimulai sebelum jam itu dilewati.
  bool _tryInsert(_Visit v, {int notBefore = 0}) {
    final weekday = input.draft.travelDate.weekday;
    for (final gap in _gaps()) {
      final prev = gap.from;
      final next = gap.to;
      if (prev.time < notBefore) continue;
      final travelIn = _cityTravel(prev.lat, prev.lng, v.lat, v.lng);
      final arrival = prev.time + travelIn;
      final start = v.locked ? v.start! : _openStart(v.place, weekday, arrival, v.minutes);
      if (start == null) continue;
      final end = start + v.minutes;
      final travelOut = _cityTravel(v.lat, v.lng, next.lat, next.lng, toReturn: identical(next, _return));
      if (start < arrival) continue;
      if (end + travelOut > next.time) continue;
      v.start = start;
      v.end = end;
      v.reason ??= _reason(prev, travelIn);
      _visits.add(v);
      _visits.sort((a, b) => a.start!.compareTo(b.start!));
      return true;
    }
    return false;
  }

  /// Jam mulai paling cepat sejak [arrival] saat tempat buka sepanjang kunjungan.
  /// Kalau tiba sebelum buka, tunggu sampai jam buka. Null kalau tidak ada.
  static int? _openStart(Place? place, int weekday, int arrival, int minutes) {
    if (place == null) return arrival;
    if (place.isOpen(weekday, arrival, arrival + minutes)) return arrival;
    int? best;
    for (final h in place.openingHours) {
      if (h.dayOfWeek != weekday || h.open <= arrival) continue;
      if (h.open + minutes > h.close) continue;
      if (best == null || h.open < best) best = h.open;
    }
    return best;
  }

  int get _recommendationCount => _visits.where((v) => v.pinId == null).length;

  /// Sisipkan lagi rekomendasi yang dipertahankan user, dengan urutan yang sama.
  /// Yang tidak muat lagi (misalnya karena durasi diperpanjang) dicatat.
  void _insertKept() {
    final kept = input.draft.keptPlaceIds;
    if (kept == null) return;
    var lastEnd = 0;
    for (final id in kept) {
      if (input.draft.excludedPlaceIds.contains(id)) continue;
      if (_visits.any((v) => v.placeId == id)) continue;
      final place = _placeById(id);
      if (place == null) continue;
      final visit = _placeVisit(place);
      if (_tryInsert(visit, notBefore: lastEnd)) {
        lastEnd = visit.end!;
      } else {
        _droppedKept.add(place.name);
      }
    }
  }

  /// Isi celah dengan rekomendasi sampai batas tempo ([TripDraft.maxStops]).
  void _fillCandidates() {
    final used = <String>{
      for (final v in _visits)
        if (v.placeId != null) v.placeId!,
      ...input.draft.excludedPlaceIds,
    };
    var inserted = true;
    while (inserted) {
      inserted = false;
      if (_recommendationCount >= input.draft.maxStops) {
        _moreAvailable = _gaps().any((g) => _bestFor(g.from, g.to, used) != null);
        return;
      }
      for (final gap in _gaps()) {
        final best = _bestFor(gap.from, gap.to, used);
        if (best == null) continue;
        if (_tryInsert(_placeVisit(best))) {
          used.add(best.id);
          inserted = true;
          break;
        }
      }
    }
  }

  /// Kandidat terbaik untuk satu celah, atau null kalau tidak ada yang muat.
  Place? _bestFor(_Node prev, _Node next, Set<String> used) {
    if (next.time - prev.time < config.minFreeSlot) return null;
    final weekday = input.draft.travelDate.weekday;
    Place? best;
    var bestScore = 1 << 30;
    for (final p in input.candidatePlaces) {
      if (used.contains(p.id)) continue;
      if (!_matchesVibe(p)) continue;
      final minutes = _stay(p.id, null, p.visitMinutes);
      final travelIn = _cityTravel(prev.lat, prev.lng, p.lat, p.lng);
      final start = prev.time + travelIn;
      final end = start + minutes;
      final travelOut = _cityTravel(p.lat, p.lng, next.lat, next.lng, toReturn: identical(next, _return));
      if (end + travelOut > next.time) continue;
      if (!p.isOpen(weekday, start, end)) continue;
      if (_tooSoonForMeal(p, start)) continue;
      final score = _score(p, travelIn + travelOut, start);
      if (score < bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return best;
  }

  /// Makan besar tidak boleh berdekatan dengan makan besar lain
  /// ([_mealGapMinutes]), supaya rencana tidak jadi tiga kali makan berturut turut.
  bool _tooSoonForMeal(Place p, int start) {
    if (p.categoryCodes.isEmpty || !_mealCategories.contains(p.categoryCodes.first)) return false;
    return _visits.any((v) =>
        _mealCategories.contains(v.categoryCode) && (v.start! - start).abs() < _mealGapMinutes);
  }

  /// Skor kandidat (kecil = lebih baik): waktu tempuh, ditambah penalti
  /// kategori yang sudah dipakai, dan bonus makan besar di jam makan.
  int _score(Place p, int travel, int start) {
    var score = travel;
    final primary = p.categoryCodes.isEmpty ? '' : p.categoryCodes.first;
    score += _repeatCategoryPenalty *
        _visits.where((v) => v.pinId == null && v.categoryCode == primary).length;
    if (_mealCategories.contains(primary)) {
      final mealTime = _mealWindows.any((w) => start >= w.$1 && start <= w.$2);
      score += mealTime ? -_mealBonus : _offMealPenalty;
    }
    return score;
  }

  _Visit _placeVisit(Place p) => _Visit(
        lat: p.lat,
        lng: p.lng,
        label: p.name,
        minutes: _stay(p.id, null, p.visitMinutes),
        placeId: p.id,
        categoryCode: p.categoryCodes.isEmpty ? '' : p.categoryCodes.first,
        categoryLabel: p.categoryCodes.isEmpty ? '' : _categoryLabel(p.categoryCodes.first),
        place: p,
      );

  bool _matchesVibe(Place p) {
    final codes = input.draft.categoryCodes;
    if (codes.isNotEmpty && !p.categoryCodes.any(codes.contains)) return false;
    final budget = PriceRange.fromDb(input.draft.budget);
    if (budget != null && p.priceRange != null && p.priceRange!.index > budget.index) return false;
    return true;
  }

  bool _validate() {
    final bounds = _bounds();
    for (var k = 0; k < bounds.length - 1; k++) {
      final prev = bounds[k];
      final next = bounds[k + 1];
      if (next.time < prev.time) return false;
      // Batas kunjungan yang sama (mulai → selesai) tidak butuh perpindahan.
      if (prev.lat == next.lat && prev.lng == next.lng && k.isOdd) continue;
      final travel = _cityTravel(prev.lat, prev.lng, next.lat, next.lng, toReturn: identical(next, _return));
      if (prev.time + travel > next.time) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Timeline

  String _name(String code) => _station(code)?.name ?? code;

  void _train({
    required int departure,
    required int arrival,
    required String from,
    required String to,
    bool feeder = false,
    int? buffer,
  }) {
    _entries.add(TrainEntry(
      departure: departure,
      arrival: arrival,
      from: _name(from),
      to: _name(to),
      bufferMinutes: buffer,
      isFeeder: feeder,
    ));
  }

  void _render(int travelToBoard, int travelHome) {
    final o = access.origin;
    final d = access.dest;
    final out = _out;
    final ret = _ret;
    final board = _station(o.point);
    final leaveHome = out.atBoard - travelToBoard;
    _clock = leaveHome;

    // Berangkat dari asal ke titik naik.
    final atBoardAlready = !_hasOrigin || _sameSpot(_originLat, _originLng, board);
    _entries.add(PointEntry(
      time: leaveHome,
      kind: PointKind.start,
      title: atBoardAlready ? AppCopy.startAt(_name(o.point)) : AppCopy.departFromPlace(_originLabel),
      subtitle: atBoardAlready ? null : input.draft.origin?.address,
      lat: atBoardAlready ? board?.lat : _originLat,
      lng: atBoardAlready ? board?.lng : _originLng,
    ));
    if (!atBoardAlready) {
      _movement(_originLat, _originLng, board?.lat ?? _originLat, board?.lng ?? _originLng,
          destLabel: _name(o.point),
          route: _accessRoute(o.point, AccessDirection.toStation),
          city: input.draft.originCity);
    }

    // Kereta pergi (dengan feeder bila lewat hub).
    if (out.originFeeder != null) {
      final f = out.originFeeder!;
      _train(departure: f.departure, arrival: f.arrival, from: o.hub!, to: o.station, feeder: true);
      _items.add(PlanItem(type: PlanItemType.feeder, start: f.departure, end: f.arrival, feederScheduleId: f.id));
    } else if (!atBoardAlready) {
      _entries.add(PointEntry(
          time: out.atBoard, kind: PointKind.station, title: _name(o.station), lat: board?.lat, lng: board?.lng));
    }
    _train(departure: out.dep, arrival: out.arr, from: o.station, to: d.station);
    _items.add(PlanItem(type: PlanItemType.whoosh, start: out.dep, end: out.arr, whooshTripId: out.trip.id, isLocked: true));
    if (out.destFeeder != null) {
      final f = out.destFeeder!;
      _train(departure: f.departure, arrival: f.arrival, from: d.station, to: d.hub!, feeder: true);
      _items.add(PlanItem(type: PlanItemType.feeder, start: f.departure, end: f.arrival, feederScheduleId: f.id));
    }
    _entries.add(PointEntry(
        time: out.hubArrival, kind: PointKind.arrive, title: AppCopy.arriveAt(_name(d.point)), lat: _hub.lat, lng: _hub.lng));

    // Kunjungan di kota tujuan.
    _clock = _hub.time;
    var posLat = _hub.lat;
    var posLng = _hub.lng;
    _route.add(RoutePoint(lat: _hub.lat, lng: _hub.lng, kind: RoutePointKind.station, label: _hub.label));
    for (final v in _visits) {
      _movement(posLat, posLng, v.lat, v.lng,
          destLabel: v.label, city: input.draft.destinationCity, arriveBy: v.start);
      if (v.locked) {
        _entries.add(LockedEntry(
          start: v.start!,
          end: v.end!,
          title: v.label,
          purposeLabel: v.categoryLabel,
          lat: v.lat,
          lng: v.lng,
        ));
        _route.add(RoutePoint(lat: v.lat, lng: v.lng, kind: RoutePointKind.locked, label: v.label));
        _items.add(PlanItem(type: PlanItemType.place, start: v.start!, end: v.end!, title: v.label, pinId: v.pinId, isLocked: true));
      } else {
        _stopNumber++;
        _entries.add(StopEntry(
          time: v.start!,
          number: _stopNumber,
          placeId: v.placeId ?? v.pinId ?? v.label,
          title: v.label,
          categoryCode: v.categoryCode,
          categoryLabel: v.categoryLabel,
          minutes: v.minutes,
          optional: v.optional,
          reason: v.reason,
          lat: v.lat,
          lng: v.lng,
          pinId: v.pinId,
        ));
        _route.add(RoutePoint(lat: v.lat, lng: v.lng, kind: RoutePointKind.stop, label: v.label, number: _stopNumber));
        _items.add(PlanItem(type: PlanItemType.place, start: v.start!, end: v.end!, title: v.label, placeId: v.placeId, pinId: v.pinId));
      }
      _clock = v.end!;
      posLat = v.lat;
      posLng = v.lng;
    }

    // Kembali ke titik naik kereta pulang.
    _movement(posLat, posLng, _return.lat, _return.lng,
        destLabel: _return.label,
        route: _accessRoute(d.point, AccessDirection.toStation),
        city: input.draft.destinationCity,
        arriveBy: _return.time,
        beforeReturn: true);
    if (ret.cityFeeder != null) {
      final f = ret.cityFeeder!;
      _train(departure: f.departure, arrival: f.arrival, from: d.hub!, to: d.station, feeder: true,
          buffer: (f.departure - _clock).clamp(0, 1 << 31).toInt());
      _items.add(PlanItem(type: PlanItemType.feeder, start: f.departure, end: f.arrival, feederScheduleId: f.id));
      _train(departure: ret.dep, arrival: ret.arr, from: d.station, to: o.station);
    } else {
      _train(departure: ret.dep, arrival: ret.arr, from: d.station, to: o.station,
          buffer: (ret.dep - _clock).clamp(0, 1 << 31).toInt());
    }
    _items.add(PlanItem(type: PlanItemType.whoosh, start: ret.dep, end: ret.arr, whooshTripId: ret.trip.id, isLocked: true));
    if (ret.homeFeeder != null) {
      final f = ret.homeFeeder!;
      _train(departure: f.departure, arrival: f.arrival, from: o.station, to: o.hub!, feeder: true);
      _items.add(PlanItem(type: PlanItemType.feeder, start: f.departure, end: f.arrival, feederScheduleId: f.id));
    }
    _entries.add(PointEntry(
        time: ret.arrivalAtPoint,
        kind: PointKind.arrive,
        title: AppCopy.arriveAt(_name(o.point)),
        lat: board?.lat,
        lng: board?.lng));
    _clock = ret.arrivalAtPoint;
    if (!atBoardAlready) {
      _movement(board?.lat ?? _originLat, board?.lng ?? _originLng, _originLat, _originLng,
          destLabel: _originLabel,
          route: _accessRoute(o.point, AccessDirection.fromStation),
          city: input.draft.originCity);
    }
    _entries.add(PointEntry(
        time: ret.arrivalAtPoint + travelHome,
        kind: PointKind.arrivedHome,
        title: AppCopy.arrived,
        lat: _originLat,
        lng: _originLng));
  }

  bool _sameSpot(double lat, double lng, Station? s) =>
      s?.lat == null || haversineKm(lat, lng, s!.lat!, s.lng!) <= config.sameSpotKm;

  /// Satu perpindahan. Ojol selalu ada. Transum hanya kalau ada rute akses
  /// stasiun dengan titik ujung yang diketahui: jalan atau ojol ke ujung rute,
  /// lalu langkah transumnya. Jarak dekat cukup jalan kaki.
  /// Satu perpindahan. Ojol selalu ada. Transum kalau ada rute offline antar
  /// titik, rute lewat titik ujung akses stasiun, atau rute akses lama. Jarak
  /// dekat cukup jalan kaki. Menit yang dipakai sama persis dengan penjadwal
  /// ([_planLeg]), jadi jam di timeline selalu bisa dijalani.
  void _movement(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng, {
    required String destLabel,
    required String city,
    AccessRoute? route,
    int? arriveBy,
    bool beforeReturn = false,
  }) {
    final leg = _planLeg(fromLat, fromLng, toLat, toLng, city: city, route: route);
    if (leg.walk) {
      _freeTime(arriveBy, leg.walkMinutes, beforeReturn);
      _entries.add(WalkEntry(minutes: leg.walkMinutes));
      _items.add(PlanItem(type: PlanItemType.travel, start: _clock, end: _clock + leg.walkMinutes, travelMode: 'walk'));
      _clock += leg.walkMinutes;
      return;
    }
    final km = leg.km;
    final ojolMinutes = leg.ojolMinutes;
    final ojolCost = leg.ojolCost;
    final transit = leg.transit;
    final recommended = leg.recommended;
    final minutes = leg.minutes;
    _freeTime(arriveBy, minutes, beforeReturn);
    _legCounter++;
    _entries.add(LegEntry(
      id: 'leg$_legCounter',
      start: _clock,
      destination: destLabel,
      distanceKm: km,
      ojol: LegOption(minutes: ojolMinutes, costRupiah: ojolCost),
      transum: transit?.option,
      transumKind: transit?.kind ?? TransitKind.bus,
      steps: transit?.steps ?? const [],
      recommended: recommended,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    ));
    _items.add(PlanItem(type: PlanItemType.travel, start: _clock, end: _clock + minutes, travelMode: recommended.name));
    _clock += minutes;
  }

  final Map<String, _LegPlan> _legCache = {};

  /// Rencana satu perpindahan: jalan kaki, atau ojol/transum dengan moda yang
  /// direkomendasikan. Dipakai penjadwal dan timeline supaya menitnya sama.
  _LegPlan _planLeg(double fromLat, double fromLng, double toLat, double toLng,
      {required String city, AccessRoute? route}) {
    final key = '${fromLat.toStringAsFixed(5)},${fromLng.toStringAsFixed(5)}>'
        '${toLat.toStringAsFixed(5)},${toLng.toStringAsFixed(5)}|$city|${route?.code}';
    return _legCache[key] ??= _computeLeg(fromLat, fromLng, toLat, toLng, city: city, route: route);
  }

  _LegPlan _computeLeg(double fromLat, double fromLng, double toLat, double toLng,
      {required String city, AccessRoute? route}) {
    final km = haversineKm(fromLat, fromLng, toLat, toLng) * _roadFactor;
    final ojolMinutes = input.travelMinutes(fromLat, fromLng, toLat, toLng);
    final ojolCost = _fare(city)?.estimate(km) ?? 0;
    final walkMinutes = (km / _walkKmh * 60).round();
    if (walkMinutes <= config.maxWalkMinutes) {
      return _LegPlan(km: km, walk: true, walkMinutes: walkMinutes, ojolMinutes: ojolMinutes, ojolCost: ojolCost);
    }

    // Rute antar titik yang sudah dihitung offline lebih tepat daripada rute
    // akses stasiun (yang butuh perjalanan awal ke titik ujungnya).
    final indexes = [input.cityTransit, input.originTransit].whereType<CityTransitIndex>();
    CityTransitRoute? cityRoute;
    AnchoredRoute? anchored;
    for (final ix in indexes) {
      cityRoute ??= ix.find(fromLat, fromLng, toLat, toLng);
    }
    if (cityRoute == null) {
      // Titik bebas (misalnya lokasi user) ke/dari stasiun: lewat titik ujung
      // akses terbaik (stasiun rel atau halte BRT).
      for (final ix in indexes) {
        anchored ??= ix.viaStation(fromLat, fromLng, toLat, toLng,
            firstMile: (aLat, aLng, bLat, bLng) => _firstMile(aLat, aLng, bLat, bLng, city));
      }
    }
    final transit = cityRoute != null
        ? _cityTransit(cityRoute)
        : anchored != null
            ? _anchoredTransit(anchored, toStation: _isStationAt(toLat, toLng))
            : route != null && route.hasAnchor
                ? _transit(route, fromLat, fromLng, toLat, toLng, city)
                : null;
    final override = input.draft.legModes[legKey(fromLat, fromLng, toLat, toLng)];
    final recommended = switch (input.draft.travelMode) {
      _ when transit == null => LegMode.ojol,
      _ when override != null => override,
      TravelMode.ojol => LegMode.ojol,
      TravelMode.transum => LegMode.transum,
      TravelMode.campur => (transit.option.minutes <= ojolMinutes + 10 && transit.option.costRupiah <= ojolCost)
          ? LegMode.transum
          : LegMode.ojol,
    };
    return _LegPlan(
      km: km,
      walk: false,
      walkMinutes: walkMinutes,
      ojolMinutes: ojolMinutes,
      ojolCost: ojolCost,
      transit: transit,
      recommended: recommended,
    );
  }

  /// Opsi transum lewat [route]: perjalanan awal/akhir (jalan atau ojol) ke
  /// ujung rute di kota, ditambah langkah rute itu sendiri.
  ({LegOption option, TransitKind kind, List<TransitStep> steps})? _transit(
    AccessRoute route,
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    String city,
  ) {
    final toStation = route.direction == AccessDirection.toStation;
    final (aLat, aLng, bLat, bLng) =
        toStation ? (fromLat, fromLng, route.anchorLat!, route.anchorLng!) : (route.anchorLat!, route.anchorLng!, toLat, toLng);
    final km = haversineKm(aLat, aLng, bLat, bLng) * _roadFactor;
    final walk = (km / _walkKmh * 60).round();
    final useWalk = walk <= config.maxWalkMinutes;
    final mileMinutes = useWalk ? walk : input.travelMinutes(aLat, aLng, bLat, bLng);
    final mileCost = useWalk ? 0 : (_fare(city)?.estimate(km) ?? 0);
    final stop = toStation ? route.steps.first.fromStop : route.steps.last.toStop;
    final mile = TransitStep(
      kind: useWalk ? TransitKind.walk : TransitKind.bus,
      text: useWalk
          ? AppCopy.walkTo(stop ?? route.name, Clock.duration(mileMinutes))
          : AppCopy.ojolTo(stop ?? route.name, Clock.duration(mileMinutes)),
      tone: CorridorTone.city,
    );
    final steps = route.steps.map(_step).toList();
    return (
      option: LegOption(minutes: mileMinutes + route.totalMinutes, costRupiah: mileCost + route.totalFare),
      kind: _mainKind(route),
      steps: toStation ? [if (mileMinutes > 0) mile, ...steps] : [...steps, if (mileMinutes > 0) mile],
    );
  }

  bool _isStationAt(double lat, double lng) =>
      input.stations.any((s) => s.lat != null && haversineKm(lat, lng, s.lat!, s.lng!) <= config.sameSpotKm);

  /// Perjalanan awal/akhir antara titik bebas dan ujung akses: jalan kaki
  /// kalau dekat, selain itu ojol.
  ({int minutes, int cost, bool walk}) _firstMile(double aLat, double aLng, double bLat, double bLng, String city) {
    final km = haversineKm(aLat, aLng, bLat, bLng) * _roadFactor;
    final walk = (km / _walkKmh * 60).round();
    if (walk <= config.maxWalkMinutes) return (minutes: walk, cost: 0, walk: true);
    return (minutes: input.travelMinutes(aLat, aLng, bLat, bLng), cost: _fare(city)?.estimate(km) ?? 0, walk: false);
  }

  ({LegOption option, TransitKind kind, List<TransitStep> steps}) _anchoredTransit(AnchoredRoute a, {required bool toStation}) {
    final inner = _cityTransit(a.route);
    final mile = TransitStep(
      kind: a.mileByWalk ? TransitKind.walk : TransitKind.bus,
      text: toStation
          ? (a.mileByWalk
              ? AppCopy.walkTo(a.anchor.name, Clock.duration(a.mileMinutes))
              : AppCopy.ojolTo(a.anchor.name, Clock.duration(a.mileMinutes)))
          : (a.mileByWalk
              ? AppCopy.walkFrom(a.anchor.name, Clock.duration(a.mileMinutes))
              : AppCopy.ojolFrom(a.anchor.name, Clock.duration(a.mileMinutes))),
      tone: CorridorTone.city,
    );
    return (
      option: LegOption(minutes: a.minutes, costRupiah: a.fare),
      kind: inner.kind,
      steps: toStation ? [if (a.mileMinutes > 0) mile, ...inner.steps] : [...inner.steps, if (a.mileMinutes > 0) mile],
    );
  }

  /// Opsi transum dari rute offline antar titik.
  ({LegOption option, TransitKind kind, List<TransitStep> steps}) _cityTransit(CityTransitRoute r) {
    TransitStep step(CityTransitStep s) {
      if (s.isWalk) {
        return TransitStep(
          kind: TransitKind.walk,
          text: AppCopy.walkTo(s.to, Clock.duration(s.minutes)),
          tone: CorridorTone.city,
        );
      }
      return TransitStep(
        kind: s.mode.isRail ? TransitKind.rail : TransitKind.bus,
        text: AppCopy.rideStep(s.from, s.to, s.stops, Clock.duration(s.minutes), s.wait),
        corridor: s.line,
        tone: s.mode.isRail
            ? CorridorTone.rail
            : s.mode == CityTransitMode.brt
                ? CorridorTone.brt
                : CorridorTone.city,
      );
    }

    return (
      option: LegOption(minutes: r.minutes, costRupiah: r.fare),
      kind: r.usesRail ? TransitKind.rail : TransitKind.bus,
      steps: [for (final s in r.steps) step(s)],
    );
  }

  /// Jeda tanpa agenda sebelum berangkat ke titik berjam tetap ([arriveBy]).
  /// Kalau cukup panjang, tampil sebagai blok waktu luang dan jam ikut maju.
  void _freeTime(int? arriveBy, int travelMinutes, bool beforeReturn) {
    if (arriveBy == null) return;
    final idle = arriveBy - (_clock + travelMinutes);
    if (idle < config.freeBlockMinutes) return;
    _entries.add(FreeTimeEntry(time: _clock, minutes: idle, beforeReturn: beforeReturn));
    _clock += idle;
  }

  TransitStep _step(AccessStep s) {
    final kind = _transitKind(s.mode);
    final corridor = [s.service, s.corridor].whereType<String>().where((c) => c.isNotEmpty).join(' · ');
    final text = kind == TransitKind.walk
        ? AppCopy.walkMinutes(s.minutes)
        : (s.fromStop != null && s.toStop != null
            ? '${s.fromStop} ke ${s.toStop} · ${Clock.duration(s.minutes)}'
            : Clock.duration(s.minutes));
    return TransitStep(
      kind: kind,
      text: text,
      corridor: corridor.isEmpty ? null : corridor,
      tone: _tone(s.mode),
    );
  }

  TransitKind _mainKind(AccessRoute route) {
    for (final s in route.steps) {
      if (s.mode != 'walk') return _transitKind(s.mode);
    }
    return TransitKind.walk;
  }

  TransitKind _transitKind(String mode) => switch (mode) {
        'walk' => TransitKind.walk,
        'whoosh' || 'ka_feeder' || 'commuter_line' => TransitKind.rail,
        _ => TransitKind.bus,
      };

  CorridorTone _tone(String mode) => switch (mode) {
        'whoosh' || 'ka_feeder' || 'commuter_line' => CorridorTone.rail,
        'bus' || 'damri' => CorridorTone.brt,
        _ => CorridorTone.city,
      };

  AccessRoute? _accessRoute(String stationCode, AccessDirection direction) {
    for (final r in input.accessRoutes) {
      if (r.stationCode == stationCode && r.direction == direction) return r;
    }
    return null;
  }

  FareRule? _fare(String city) {
    FareRule? fallback;
    for (final f in input.fareRules) {
      if (f.mode != 'two_wheeler') continue;
      if (f.city == city) return f;
      fallback ??= f;
    }
    return fallback;
  }

  Station? _station(String code) {
    for (final s in input.stations) {
      if (s.code == code) return s;
    }
    return null;
  }

  Place? _placeById(String id) {
    for (final p in input.candidatePlaces) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Waktu tempuh asal user ke stasiun [code] (0 kalau asal belum dipilih).
  int _travelToCode(String code, {bool home = false}) {
    final s = _station(code);
    if (s == null || s.lat == null) return 0;
    if (!_hasOrigin || _sameSpot(_originLat, _originLng, s)) return 0;
    final city = input.draft.originCity;
    return home
        ? _planLeg(s.lat!, s.lng!, _originLat, _originLng,
                city: city, route: _accessRoute(code, AccessDirection.fromStation))
            .minutes
        : _planLeg(_originLat, _originLng, s.lat!, s.lng!,
                city: city, route: _accessRoute(code, AccessDirection.toStation))
            .minutes;
  }

  /// Menit perpindahan di kota tujuan, sama dengan yang dipakai timeline.
  /// [toReturn] = menuju titik naik kereta pulang (memakai rute akses stasiun).
  int _cityTravel(double fromLat, double fromLng, double toLat, double toLng, {bool toReturn = false}) =>
      _planLeg(fromLat, fromLng, toLat, toLng,
              city: input.draft.destinationCity,
              route: toReturn ? _accessRoute(access.dest.point, AccessDirection.toStation) : null)
          .minutes;

  int _travelXY(double fromLat, double fromLng, double toLat, double toLng) =>
      input.travelMinutes(fromLat, fromLng, toLat, toLng);

  String? _reason(_Node prev, int travelIn) {
    if (travelIn <= config.maxWalkMinutes) {
      return AppCopy.distanceFromStation(prev.label, AppCopy.walkAway(travelIn));
    }
    return null;
  }

  String _categoryLabel(String code) {
    for (final v in VibeCatalog.vibes) {
      for (final s in VibeCatalog.subsOf(v.code)) {
        if (s.code == code) return s.label;
      }
    }
    return code;
  }

  String _purposeLabel(PinPurpose p) => switch (p) {
        PinPurpose.kerja => AppCopy.purposeKerja,
        PinPurpose.janji => AppCopy.purposeJanji,
        PinPurpose.main => AppCopy.purposeMain,
        PinPurpose.lainnya => AppCopy.purposeLainnya,
      };

  String _budgetLabel(String? b) => switch (b) {
        'sedang' => AppCopy.budgetSedang,
        'mahal' => AppCopy.budgetSultan,
        _ => AppCopy.budgetHemat,
      };
}

/// Hasil [_Run._planLeg].
class _LegPlan {
  const _LegPlan({
    required this.km,
    required this.walk,
    required this.walkMinutes,
    required this.ojolMinutes,
    required this.ojolCost,
    this.transit,
    this.recommended = LegMode.ojol,
  });

  final double km;
  final bool walk;
  final int walkMinutes;
  final int ojolMinutes;
  final int ojolCost;
  final ({LegOption option, TransitKind kind, List<TransitStep> steps})? transit;
  final LegMode recommended;

  int get minutes => walk
      ? walkMinutes
      : recommended == LegMode.transum && transit != null
          ? transit!.option.minutes
          : ojolMinutes;
}
