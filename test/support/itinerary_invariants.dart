import 'package:otwey/features/places/domain/place.dart';
import 'package:otwey/features/planner/domain/itinerary.dart';
import 'package:otwey/features/planner/domain/leg_mode.dart';
import 'package:otwey/features/planner/domain/planner_config.dart';
import 'package:otwey/features/trip_setup/domain/plan_pin.dart';
import 'package:otwey/features/trip_setup/domain/trip_draft.dart';

/// Pelanggaran aturan "rencana harus bisa dijalani" pada satu itinerary.
///
/// Timeline dijalani dari awal dengan jam berjalan, seperti user di lapangan:
/// setiap langkah harus bisa dimulai pada jam yang tertulis, kereta terkejar
/// dengan buffer, tempat buka, sampai rumah sebelum batas, tujuan Wajib ada.
///
/// [modeOf] = moda tiap perpindahan (default rekomendasi planner).
List<String> itineraryViolations(
  Itinerary it,
  TripDraft draft,
  List<Place> places, {
  PlannerConfig config = const PlannerConfig(),
  LegMode Function(LegEntry leg)? modeOf,
}) {
  final out = <String>[];
  final byId = {for (final p in places) p.id: p};
  final weekday = draft.travelDate.weekday;
  var clock = -1;
  TimelineEntry? prev;
  var lastTrainArrival = 0;
  String at(int m) => '${m ~/ 60}.${(m % 60).toString().padLeft(2, '0')}';

  void need(bool ok, String msg) {
    if (!ok) out.add(msg);
  }

  for (final e in it.entries) {
    switch (e) {
      case final PointEntry p:
        switch (p.kind) {
          case PointKind.start:
            need(p.time >= draft.earliestDeparture,
                'berangkat ${at(p.time)} sebelum jam paling awal ${at(draft.earliestDeparture)}');
            clock = p.time;
          case PointKind.station:
          case PointKind.arrive:
            need(p.time >= clock, '${p.title} ${at(p.time)} padahal baru sampai ${at(clock)}');
            if (p.time > clock) clock = p.time;
          case PointKind.arrivedHome:
            need(p.time >= clock, 'sampai rumah ${at(p.time)} padahal jam berjalan ${at(clock)}');
            need(p.time <= draft.latestReturn, 'sampai rumah ${at(p.time)} lewat batas ${at(draft.latestReturn)}');
        }
      case final LegEntry l:
        need(l.start >= clock, 'perpindahan ke ${l.destination} mulai ${at(l.start)} sebelum ${at(clock)}');
        final mode = modeOf?.call(l) ?? l.recommended;
        need(mode == LegMode.ojol || l.hasTransum, 'transum dipilih tapi tidak ada data ke ${l.destination}');
        clock = l.start + l.option(mode).minutes;
      case final WalkEntry w:
        clock += w.minutes;
      case final FreeTimeEntry f:
        need(f.time >= clock, 'waktu luang ${at(f.time)} sebelum ${at(clock)}');
        clock = f.time + f.minutes;
      case final StopEntry s:
        need(s.time >= clock, '${s.title} mulai ${at(s.time)} padahal baru tiba ${at(clock)}');
        final place = byId[s.placeId];
        if (place != null) {
          need(place.isOpen(weekday, s.time, s.time + s.minutes),
              '${s.title} tidak buka ${at(s.time)}-${at(s.time + s.minutes)}');
        }
        clock = s.time + s.minutes;
      case final LockedEntry k:
        need(k.start >= clock, '${k.title} jam ${at(k.start)} padahal baru tiba ${at(clock)}');
        clock = k.end;
      case final TrainEntry t:
        need(t.arrival > t.departure, 'kereta ${t.from} tiba sebelum berangkat');
        if (prev is TrainEntry) {
          need(t.departure >= lastTrainArrival + config.transferMinutes,
              'pindah ke ${t.from} ${at(t.departure)} kurang dari ${config.transferMinutes} mnt setelah tiba ${at(lastTrainArrival)}');
        } else if (prev is PointEntry && prev.kind == PointKind.start) {
          // Mulai langsung di stasiun: jam mulai sudah memperhitungkan buffer.
          need(clock <= t.departure, 'kereta ${t.from} ${at(t.departure)} sudah lewat');
        } else {
          final buffer = t.isFeeder ? config.bufferBeforeFeeder : config.bufferBeforeTrain;
          need(clock + buffer <= t.departure,
              'sampai ${t.from} ${at(clock)}, kurang dari $buffer mnt sebelum kereta ${at(t.departure)}');
        }
        lastTrainArrival = t.arrival;
        clock = t.arrival;
    }
    prev = e;
  }

  // Tujuan Wajib tidak boleh hilang diam diam.
  for (final pin in draft.pins.where((p) => p.priority == PinPriority.wajib)) {
    final present = it.stops.any((s) => s.pinId == pin.id) || it.locked.any((l) => l.title == pin.name);
    need(present, 'tujuan Wajib ${pin.name} hilang');
  }
  final recs = it.recommendedPlaceIds;
  need(recs.length <= draft.maxStops, '${recs.length} rekomendasi melebihi tempo ${draft.maxStops}');
  need(recs.toSet().length == recs.length, 'ada tempat yang dikunjungi dua kali');
  return out;
}
