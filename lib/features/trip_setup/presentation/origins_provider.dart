import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../planner/data/supabase_schedule_repository.dart';
import '../data/seed_origin_repository.dart';
import '../data/supabase_origin_repository.dart';
import '../domain/origin_point.dart';
import '../domain/origin_repository.dart';

final originRepositoryProvider = Provider<OriginRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseOriginRepository(
      ref.watch(supabaseClientProvider),
      ref.watch(scheduleRepositoryProvider),
    );
  }
  return SeedOriginRepository();
});

/// Titik berangkat di [city]. Supabase gagal → fallback CSV seed.
final originsProvider = FutureProvider.family<List<OriginPoint>, String>((ref, city) async {
  final repo = ref.watch(originRepositoryProvider);
  try {
    return await repo.fetchByCity(city);
  } catch (_) {
    if (repo is SeedOriginRepository) rethrow;
    return SeedOriginRepository().fetchByCity(city);
  }
});