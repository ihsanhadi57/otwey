/// Aturan tarif ojol dari `mst_fare_rule`. Angka hanya dari data bersumber.
class FareRule {
  const FareRule({
    required this.code,
    required this.mode,
    required this.baseFare,
    required this.perKmFare,
    required this.minFare,
    this.city,
  });

  final String code;

  /// `two_wheeler` atau `drive`.
  final String mode;

  /// Null berarti berlaku di semua kota.
  final String? city;
  final int baseFare;
  final int perKmFare;
  final int minFare;

  /// Perkiraan tarif untuk [km]. Hasil selalu dibulatkan dan minimal [minFare].
  int estimate(double km) {
    final raw = (baseFare + perKmFare * km).round();
    return raw < minFare ? minFare : raw;
  }
}