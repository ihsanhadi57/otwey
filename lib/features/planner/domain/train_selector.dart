import 'planner_config.dart';
import 'schedule.dart';

/// Pemilihan kereta pergi dan pulang (PRD 8.2 langkah 2 dan 3). Murni, tanpa I/O.
class TrainSelector {
  const TrainSelector([this.config = const PlannerConfig()]);

  final PlannerConfig config;

  /// Kereta pergi paling awal yang masih bisa dikejar.
  ///
  /// [readyAtStation] = jam user paling cepat bisa tiba di stasiun asal.
  WhooshTrip? earliestOutbound({
    required List<WhooshTrip> trips,
    required String fromStation,
    required String toStation,
    required int readyAtStation,
  }) {
    WhooshTrip? best;
    for (final t in trips) {
      final dep = t.departureFrom(fromStation);
      final arr = t.arrivalAt(toStation);
      if (dep == null || arr == null || arr <= dep) continue;
      if (dep - config.bufferBeforeTrain < readyAtStation) continue;
      if (best == null || dep < best.departureFrom(fromStation)!) best = t;
    }
    return best;
  }

  /// Kereta pergi paling akhir yang tetap tiba di stasiun tujuan paling lambat [mustArriveBy].
  ///
  /// Dipakai jika ada tujuan berjam tetap, supaya user tidak menunggu terlalu lama.
  WhooshTrip? latestOutboundArrivingBy({
    required List<WhooshTrip> trips,
    required String fromStation,
    required String toStation,
    required int readyAtStation,
    required int mustArriveBy,
  }) {
    WhooshTrip? best;
    for (final t in trips) {
      final dep = t.departureFrom(fromStation);
      final arr = t.arrivalAt(toStation);
      if (dep == null || arr == null || arr <= dep) continue;
      if (dep - config.bufferBeforeTrain < readyAtStation) continue;
      if (arr + config.bufferAfterTrain > mustArriveBy) continue;
      if (best == null || dep > best.departureFrom(fromStation)!) best = t;
    }
    return best;
  }

  /// Kereta pulang paling akhir yang membuat user tiba di stasiun asal paling lambat
  /// [mustArriveBy] (jam sampai paling telat dikurangi perjalanan stasiun ke rumah).
  WhooshTrip? latestReturn({
    required List<WhooshTrip> trips,
    required String fromStation,
    required String toStation,
    required int earliestAtStation,
    required int mustArriveBy,
  }) {
    WhooshTrip? best;
    for (final t in trips) {
      final dep = t.departureFrom(fromStation);
      final arr = t.arrivalAt(toStation);
      if (dep == null || arr == null || arr <= dep) continue;
      if (dep - config.bufferBeforeTrain < earliestAtStation) continue;
      if (arr + config.bufferAfterTrain > mustArriveBy) continue;
      if (best == null || dep > best.departureFrom(fromStation)!) best = t;
    }
    return best;
  }
}
