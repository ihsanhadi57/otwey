import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile.dart';

/// TODO(hadi): ambil dari Supabase Auth dan tabel profil.
final profileProvider = Provider<Profile>(
  (ref) => const Profile(name: 'Raka', tripCount: 3, visitedCount: 14),
);
