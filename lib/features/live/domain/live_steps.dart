import '../../planner/domain/itinerary.dart';

/// Jenis langkah di mode jalan.
enum LiveStepKind { start, station, train, feeder, arrive, stop, locked, free, home }

/// Satu langkah yang bisa dicentang di mode jalan, beserta cara menuju ke sana.
class LiveStep {
  const LiveStep({
    required this.kind,
    required this.time,
    required this.title,
    this.endTime,
    this.subtitle,
    this.lat,
    this.lng,
    this.leg,
    this.walkMinutes,
    this.placeId,
  });

  final LiveStepKind kind;

  /// Jam mulai langkah (menit sejak tengah malam).
  final int time;

  /// Jam selesai, kalau langkahnya punya durasi (kereta, kunjungan).
  final int? endTime;
  final String title;
  final String? subtitle;
  final double? lat;
  final double? lng;

  /// Perpindahan sebelum langkah ini, kalau ada.
  final LegEntry? leg;

  /// Jalan kaki sebelum langkah ini (tanpa pilihan moda).
  final int? walkMinutes;

  /// Id tempat katalog (untuk place_id Google di petunjuk arah), kalau ada.
  final String? placeId;

  bool get hasPoint => lat != null && lng != null;
}

/// Ubah timeline itinerary jadi urutan langkah mode jalan. Perpindahan
/// (ojol/transum/jalan kaki) menempel ke langkah sesudahnya.
List<LiveStep> liveSteps(Itinerary itinerary) {
  final steps = <LiveStep>[];
  LegEntry? leg;
  int? walk;
  for (final e in itinerary.entries) {
    switch (e) {
      case final LegEntry l:
        leg = l;
        continue;
      case final WalkEntry w:
        walk = w.minutes;
        continue;
      case final PointEntry p:
        steps.add(LiveStep(
          kind: switch (p.kind) {
            PointKind.start => LiveStepKind.start,
            PointKind.station => LiveStepKind.station,
            PointKind.arrive => LiveStepKind.arrive,
            PointKind.arrivedHome => LiveStepKind.home,
          },
          time: p.time,
          title: p.title,
          subtitle: p.subtitle,
          lat: p.lat,
          lng: p.lng,
          leg: leg,
          walkMinutes: walk,
        ));
      case final TrainEntry t:
        steps.add(LiveStep(
          kind: t.isFeeder ? LiveStepKind.feeder : LiveStepKind.train,
          time: t.departure,
          endTime: t.arrival,
          title: '${t.from} → ${t.to}',
          leg: leg,
          walkMinutes: walk,
        ));
      case final StopEntry s:
        steps.add(LiveStep(
          kind: LiveStepKind.stop,
          time: s.time,
          endTime: s.time + s.minutes,
          title: s.title,
          subtitle: s.categoryLabel,
          lat: s.lat,
          lng: s.lng,
          leg: leg,
          walkMinutes: walk,
          placeId: s.placeId,
        ));
      case final LockedEntry l:
        steps.add(LiveStep(
          kind: LiveStepKind.locked,
          time: l.start,
          endTime: l.end,
          title: l.title,
          subtitle: l.purposeLabel,
          lat: l.lat,
          lng: l.lng,
          leg: leg,
          walkMinutes: walk,
        ));
      case final FreeTimeEntry f:
        steps.add(LiveStep(
          kind: LiveStepKind.free,
          time: f.time,
          endTime: f.time + f.minutes,
          title: '',
          leg: leg,
          walkMinutes: walk,
        ));
    }
    leg = null;
    walk = null;
  }
  return steps;
}

/// Indeks langkah yang sedang atau akan dijalani pada jam [now]: langkah
/// pertama yang belum selesai. Panjang list = semua selesai.
int currentStepAt(List<LiveStep> steps, int now) {
  for (var i = 0; i < steps.length; i++) {
    final end = steps[i].endTime ?? steps[i].time;
    if (end > now) return i;
  }
  return steps.length;
}

/// Hari perjalanan dibanding [today]: negatif = sudah lewat, 0 = hari ini,
/// positif = berapa hari lagi.
int daysUntil(DateTime trip, DateTime today) {
  final a = DateTime(trip.year, trip.month, trip.day);
  final b = DateTime(today.year, today.month, today.day);
  return a.difference(b).inDays;
}
