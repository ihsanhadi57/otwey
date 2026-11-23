/// Arah perjalanan. Nilai [dbValue] sama dengan enum `trip_direction` di database.
enum TripDirection {
  jakartaToBandung('jakarta_to_bandung', 'Jakarta', 'Bandung'),
  bandungToJakarta('bandung_to_jakarta', 'Bandung', 'Jakarta');

  const TripDirection(this.dbValue, this.originCity, this.destinationCity);

  final String dbValue;
  final String originCity;
  final String destinationCity;

  TripDirection get reversed => this == TripDirection.jakartaToBandung
      ? TripDirection.bandungToJakarta
      : TripDirection.jakartaToBandung;

  static TripDirection fromDb(String value) =>
      values.firstWhere((d) => d.dbValue == value);
}
