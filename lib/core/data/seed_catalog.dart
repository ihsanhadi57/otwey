import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

import '../utils/seed_validate.dart';

/// Membaca CSV seed dari asset (sumber yang sama dengan importer tool/).
/// Hasil di-cache supaya semua repository mode seed berbagi satu parse.
abstract final class SeedCatalog {
  static Future<SeedData>? _cached;

  static Future<SeedData> load() => _cached ??= _load();

  static Future<SeedData> _load() async {
    final files = <String, String>{};
    for (final name in seedFileNames) {
      try {
        files[name] = await rootBundle.loadString('supabase/seed/$name.csv');
      } on FlutterError {
        // File tidak ada di asset: validateSeed yang melaporkan.
      }
    }
    final data = validateSeed(files);
    if (!data.ok) throw SeedDataException(data.issues);
    return data;
  }
}