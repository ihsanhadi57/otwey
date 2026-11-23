/// Konstanta planner. Sumber: docs/PRD.md bagian 8.1.
class PlannerConfig {
  const PlannerConfig({
    this.bufferBeforeTrain = 30,
    this.bufferAfterTrain = 10,
    this.bufferBetweenStops = 10,
    this.maxWalkMinutes = 15,
    this.minFreeSlot = 45,
    this.warningThreshold = 30,
    this.freeBlockMinutes = 30,
    this.earlierReturnMinutes = 60,
    this.bufferBeforeFeeder = 15,
    this.transferMinutes = 5,
    this.sameSpotKm = 0.3,
  });

  final int bufferBeforeTrain;
  final int bufferAfterTrain;
  final int bufferBetweenStops;
  final int maxWalkMinutes;
  final int minFreeSlot;
  final int warningThreshold;

  /// Jeda tanpa agenda minimal sekian menit tampil sebagai blok "Waktu luang".
  final int freeBlockMinutes;

  /// Kereta pulang lebih awal hanya ditawarkan kalau minimal sekian menit lebih cepat.
  final int earlierReturnMinutes;

  /// Tiba di stasiun KA Feeder paling lambat sekian menit sebelum berangkat.
  final int bufferBeforeFeeder;

  /// Pindah kereta di stasiun yang sama (Whoosh ⇄ KA Feeder di Padalarang).
  final int transferMinutes;

  /// Jarak (km) yang dianggap titik yang sama, tidak perlu perpindahan.
  final double sameSpotKm;
}
