import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../domain/fare_rule.dart';
import '../domain/fare_rule_repository.dart';
import 'seed_fare_rule_repository.dart';

final fareRuleRepositoryProvider = Provider<FareRuleRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseFareRuleRepository(ref.watch(supabaseClientProvider));
  }
  return SeedFareRuleRepository();
});

class SupabaseFareRuleRepository implements FareRuleRepository {
  SupabaseFareRuleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<FareRule>> fetchAll() async {
    final rows = await _client
        .from('mst_fare_rule')
        .select('code, mode, city, base_fare, per_km_fare, min_fare')
        .eq('is_active', true)
        .order('code');

    return [
      for (final r in rows)
        FareRule(
          code: r['code'] as String,
          mode: r['mode'] as String,
          city: r['city'] as String?,
          baseFare: r['base_fare'] as int,
          perKmFare: r['per_km_fare'] as int,
          minFare: r['min_fare'] as int,
        ),
    ];
  }
}