import 'fare_rule.dart';

abstract interface class FareRuleRepository {
  /// Semua aturan tarif aktif.
  Future<List<FareRule>> fetchAll();
}