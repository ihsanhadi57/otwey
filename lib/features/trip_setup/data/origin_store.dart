import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/origin_point.dart';

final originStoreProvider = Provider<OriginStore>((ref) => OriginStore());

/// Titik berangkat terakhir per kota, disimpan di perangkat (bukan server).
class OriginStore {
  static String _key(String city) => 'origin.v1.${city.toLowerCase()}';

  Future<OriginPoint?> load(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(city));
      return raw == null ? null : OriginPoint.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String city, OriginPoint origin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(city), jsonEncode(origin.toJson()));
    } catch (_) {
      // Gagal simpan tidak menghalangi rencana.
    }
  }
}
