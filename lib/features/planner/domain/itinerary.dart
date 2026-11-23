import 'leg_mode.dart';

/// Jenis titik di timeline.
/// [arrive] = turun dari kereta (jam tiba ditonjolkan).
enum PointKind { start, station, arrive, arrivedHome }

/// Moda satu langkah transum.
enum TransitKind { walk, rail, bus }

/// Kelompok warna koridor: rel (LRT, KRL, KA Feeder), BRT, atau angkutan kota.
enum CorridorTone { rail, brt, city }

/// Jenis titik rute di kota tujuan, untuk peta hasil.
enum RoutePointKind { station, stop, locked }

/// Status rencana untuk kartu TimeBudget (PRD 8.2 langkah 9).
enum PlanStatus { safe, tight, impossible }

/// Titik rute berurutan di kota tujuan: stasiun tiba, tempat, tujuan terkunci,
/// stasiun pulang. Koordinat dalam derajat WGS84.
class RoutePoint {
  const RoutePoint({required this.lat, required this.lng, required this.kind, required this.label, this.number});

  final double lat;
  final double lng;
  final RoutePointKind kind;
  final String label;

  /// Nomor urut untuk [RoutePointKind.stop].
  final int? number;
}

/// Satu baris timeline itinerary. Jam dalam menit sejak tengah malam.
sealed class TimelineEntry {
  const TimelineEntry();
}

/// Titik penanda: berangkat, tiba di stasiun, sampai rumah.
class PointEntry extends TimelineEntry {
  const PointEntry({
    required this.time,
    required this.kind,
    required this.title,
    this.subtitle,
    this.lat,
    this.lng,
  });

  final double? lat;
  final double? lng;
  final int time;
  final PointKind kind;
  final String title;
  final String? subtitle;
}

/// Naik kereta cepat. Sengaja tampil sederhana, satu langkah biasa.
class TrainEntry extends TimelineEntry {
  const TrainEntry({
    required this.departure,
    required this.arrival,
    required this.from,
    required this.to,
    this.bufferMinutes,
    this.isFeeder = false,
  });

  /// True untuk KA Feeder (Padalarang ⇄ Bandung), false untuk kereta cepat.
  final bool isFeeder;

  final int departure;
  final int arrival;
  final String from;
  final String to;

  /// Menit tiba di stasiun sebelum kereta pulang berangkat (khusus kereta pulang).
  final int? bufferMinutes;
}

/// Opsi tempuh satu perpindahan.
class LegOption {
  const LegOption({required this.minutes, required this.costRupiah});

  final int minutes;
  final int costRupiah;
}

/// Satu langkah transum, misalnya jalan kaki ke halte atau naik koridor tertentu.
class TransitStep {
  const TransitStep({required this.kind, required this.text, this.corridor, this.tone = CorridorTone.rail});

  final TransitKind kind;
  final String text;

  /// Nama layanan dan koridor, misalnya "LRT Jabodebek" atau "Metro Jabar Trans K4".
  final String? corridor;
  final CorridorTone tone;
}

/// Perpindahan antar titik. User bisa pilih ojol atau transum.
class LegEntry extends TimelineEntry {
  const LegEntry({
    required this.id,
    required this.start,
    required this.destination,
    required this.distanceKm,
    required this.ojol,
    required this.transum,
    required this.transumKind,
    required this.steps,
    required this.recommended,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  /// Titik asal dan tujuan, untuk mencari rute transum langsung (Google).
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  bool get hasPoints => fromLat != null && fromLng != null && toLat != null && toLng != null;

  /// Jam mulai perpindahan. Jam tiba = [start] + menit opsi yang dipilih.
  final int start;

  final String id;
  final String destination;
  final double distanceKm;
  final LegOption ojol;

  /// Null kalau belum ada data transum untuk rute ini. Tidak pernah ditebak.
  final LegOption? transum;

  bool get hasTransum => transum != null;

  /// Moda utama transum, untuk ikon opsi.
  final TransitKind transumKind;
  final List<TransitStep> steps;

  /// Pilihan planner saat preferensi "Campur".
  final LegMode recommended;

  LegOption option(LegMode mode) => mode == LegMode.transum && transum != null ? transum! : ojol;

  /// Moda efektif: pilihan user, kecuali transum yang tidak tersedia.
  LegMode effective(LegMode mode) => mode == LegMode.transum && transum == null ? LegMode.ojol : mode;

  int arrival(LegMode mode) => start + option(mode).minutes;
}

/// Jalan kaki pendek antar tempat yang berdekatan (tanpa pilihan moda).
class WalkEntry extends TimelineEntry {
  const WalkEntry({required this.minutes});

  final int minutes;
}

/// Tempat yang dikunjungi.
class StopEntry extends TimelineEntry {
  const StopEntry({
    required this.time,
    required this.number,
    required this.placeId,
    required this.title,
    required this.categoryCode,
    required this.categoryLabel,
    required this.minutes,
    this.optional = false,
    this.reason,
    this.lat,
    this.lng,
    this.pinId,
  });

  final double? lat;
  final double? lng;

  /// Id pin kalau tempat ini tujuan yang ditambahkan user, null kalau rekomendasi planner.
  final String? pinId;

  bool get isRecommendation => pinId == null;

  /// Alasan planner memilih tempat ini di slot ini (tampil di detail stop).
  final String? reason;

  final int time;
  final int number;
  final String placeId;
  final String title;
  final String categoryCode;
  final String categoryLabel;
  final int minutes;

  /// True untuk tujuan "Kalau sempat" yang ternyata masuk.
  final bool optional;
}

/// Waktu luang tanpa agenda, misalnya setelah user menghapus tempat.
/// Jam mulai [time], lalu [minutes] menit bebas sebelum jalan ke titik berikutnya.
class FreeTimeEntry extends TimelineEntry {
  const FreeTimeEntry({required this.time, required this.minutes, this.beforeReturn = false});

  final int time;
  final int minutes;

  /// True kalau setelah waktu luang ini user jalan ke stasiun pulang.
  final bool beforeReturn;
}

/// Tujuan Wajib berjam tetap, terkunci.
class LockedEntry extends TimelineEntry {
  const LockedEntry({
    required this.start,
    required this.end,
    required this.title,
    required this.purposeLabel,
    this.lat,
    this.lng,
  });

  final double? lat;
  final double? lng;
  final int start;
  final int end;
  final String title;
  final String purposeLabel;
}

/// Itinerary satu hari.
class Itinerary {
  const Itinerary({
    required this.originCity,
    required this.destinationCity,
    required this.originLabel,
    required this.date,
    required this.vibeLabel,
    required this.budgetLabel,
    required this.entries,
    required this.freeMinutes,
    required this.latestReturn,
    this.status = PlanStatus.safe,
    this.route = const [],
    this.returnDeparture,
    this.earlierReturnDeparture,
    this.moreStopsAvailable = false,
    this.droppedPlaceNames = const [],
    this.droppedPinNames = const [],
  });

  /// Status saat rencana dibuat. Trip tersimpan menyimpan status ini juga.
  final PlanStatus status;

  /// Tempat pilihan user yang tidak muat lagi setelah edit (misalnya durasi diperpanjang).
  final List<String> droppedPlaceNames;

  /// Tujuan user yang dilepas planner karena tidak muat.
  final List<String> droppedPinNames;

  /// Jam berangkat kereta pulang dari kota tujuan.
  final int? returnDeparture;

  /// Kereta pulang lebih awal yang tetap memuat semua tempat di rencana,
  /// diisi planner kalau selisihnya cukup besar. Null kalau tidak ada.
  final int? earlierReturnDeparture;

  /// True kalau masih ada tempat rekomendasi yang muat, tapi tertahan batas tempo.
  final bool moreStopsAvailable;

  /// Rute di kota tujuan secara berurutan, untuk peta.
  final List<RoutePoint> route;

  final String originCity;
  final String destinationCity;
  final String originLabel;
  final DateTime date;
  final String vibeLabel;
  final String budgetLabel;
  final List<TimelineEntry> entries;
  final int freeMinutes;
  final int latestReturn;

  List<LegEntry> get legs => entries.whereType<LegEntry>().toList();
  List<StopEntry> get stops => entries.whereType<StopEntry>().toList();
  List<LockedEntry> get locked => entries.whereType<LockedEntry>().toList();
  List<TrainEntry> get trains => entries.whereType<TrainEntry>().toList();

  /// Kereta cepat saja (tanpa KA Feeder): pergi lalu pulang.
  List<TrainEntry> get whooshTrains => trains.where((t) => !t.isFeeder).toList();
  List<FreeTimeEntry> get freeBlocks => entries.whereType<FreeTimeEntry>().toList();

  /// Id tempat rekomendasi planner, urut jam kunjungan.
  List<String> get recommendedPlaceIds => [
        for (final s in stops)
          if (s.isRecommendation) s.placeId,
      ];

  int get startTime => entries.whereType<PointEntry>().first.time;

  int get homeArrival => entries
      .whereType<PointEntry>()
      .lastWhere((p) => p.kind == PointKind.arrivedHome)
      .time;

  /// Menit cadangan sebelum batas pulang.
  int get spareMinutes => latestReturn - homeArrival;

  int? get returnBuffer {
    for (final t in trains.reversed) {
      if (t.bufferMinutes != null) return t.bufferMinutes;
    }
    return null;
  }

  /// Total ongkos jalan (rupiah) sesuai pilihan moda tiap perpindahan.
  int totalCost(Map<String, LegMode> choice) => legs.fold(
        0,
        (sum, leg) => sum + leg.option(choice[leg.id] ?? leg.recommended).costRupiah,
      );

  /// Apakah perpindahan [legId] masih muat kalau memakai [mode] tanpa
  /// menyusun ulang jadwal: tiba sebelum langkah berjam berikutnya (tempat,
  /// janji, kereta dengan buffernya, atau jam sampai rumah yang tertulis).
  /// Untuk trip tersimpan yang tidak dijadwal ulang.
  bool legFits(String legId, LegMode mode, {int bufferBeforeTrain = 30, int bufferBeforeFeeder = 15}) {
    final i = entries.indexWhere((e) => e is LegEntry && e.id == legId);
    if (i < 0) return false;
    final leg = entries[i] as LegEntry;
    if (mode == LegMode.transum && !leg.hasTransum) return false;
    var arrival = leg.arrival(mode);
    for (final e in entries.skip(i + 1)) {
      switch (e) {
        case final WalkEntry w:
          arrival += w.minutes;
          continue;
        case final StopEntry s:
          return arrival <= s.time;
        case final LockedEntry k:
          return arrival <= k.start;
        case final TrainEntry t:
          return arrival + (t.isFeeder ? bufferBeforeFeeder : bufferBeforeTrain) <= t.departure;
        case final PointEntry p:
          return arrival <= p.time;
        default:
          return true;
      }
    }
    return true;
  }

  StopEntry? stopByPlace(String placeId) {
    for (final s in stops) {
      if (s.placeId == placeId) return s;
    }
    return null;
  }
}
