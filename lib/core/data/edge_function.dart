import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'supabase_client_provider.dart';

/// Pemanggil Edge Function Supabase. Semua API pihak ketiga (Google) lewat
/// sini supaya key tidak pernah ada di aplikasi. Null kalau Supabase belum
/// dikonfigurasi (mode demo offline).
final edgeFunctionsProvider = Provider<EdgeFunctions?>((ref) {
  if (!Env.hasSupabase) return null;
  final client = ref.watch(supabaseClientProvider);
  return EdgeFunctions((name, body) async {
    final res = await client.functions.invoke(name, body: body);
    return res.data;
  });
});

typedef EdgeInvoke = Future<Object?> Function(String name, Map<String, dynamic> body);

class EdgeFunctions {
  const EdgeFunctions(this._invoke, {this.timeout = const Duration(seconds: 12)});

  final EdgeInvoke _invoke;
  final Duration timeout;

  /// Panggil function [name]. Gagal, timeout, atau error server → null,
  /// sehingga pemanggil bisa kembali ke perilaku offline tanpa crash.
  Future<Object?> call(String name, Map<String, dynamic> body) async {
    try {
      return await _invoke(name, body).timeout(timeout);
    } on TimeoutException {
      return null;
    } on FunctionException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
