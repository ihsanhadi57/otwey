import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // RULES: tetap supabase v2 selama hackathon, rename ke publishableKey saat v3.
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      try {
        await client.auth.signInAnonymously();
      } catch (_) {
        // Offline atau anonymous sign-in belum aktif: tetap jalan dengan data lokal.
      }
    }
  }

  // Tanpa percobaan ulang otomatis Riverpod 3: kegagalan (rencana mustahil,
  // jaringan putus) langsung tampil ke user, bukan loading berpuluh detik.
  runApp(ProviderScope(retry: (_, _) => null, child: const OtweyApp()));
}
