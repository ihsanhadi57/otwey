import '../../../core/data/seed_catalog.dart';
import '../../../core/utils/seed_validate.dart';
import '../domain/fare_rule.dart';
import '../domain/fare_rule_repository.dart';

/// Mode demo offline: aturan tarif dari CSV seed yang sama dengan importer.
class SeedFareRuleRepository implements FareRuleRepository {
  @override
  Future<List<FareRule>> fetchAll() async => rulesFrom(await SeedCatalog.load());

  static List<FareRule> rulesFrom(SeedData data) => [
        for (final r in data.fareRules)
          FareRule(
            code: r.code,
            mode: r.mode,
            city: r.city.isEmpty ? null : r.city,
            baseFare: r.baseFare,
            perKmFare: r.perKmFare,
            minFare: r.minFare,
          ),
      ];
}