/// Tempo trip: berapa banyak tempat rekomendasi yang diisi planner.
///
/// Tujuan yang ditambahkan user sendiri (pin) tidak dihitung dalam batas ini.
enum TripPace {
  santai(2),
  pas(4),
  padat(6);

  const TripPace(this.maxStops);

  final int maxStops;

  /// Batas yang bisa diatur manual lewat stepper.
  static const minStops = 0;
  static const maxStopsLimit = 8;

  static const fallback = TripPace.pas;

  /// Tempo yang cocok dengan [stops], atau null kalau angkanya custom.
  static TripPace? of(int stops) {
    for (final p in values) {
      if (p.maxStops == stops) return p;
    }
    return null;
  }
}
