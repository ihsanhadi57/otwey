import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/city_transit.dart';

/// Rute transum offline per kota dari aset `supabase/seed/derived/`.
/// Kota tanpa file (misalnya Bandung) menghasilkan indeks kosong.
final cityTransitProvider = FutureProvider.family<CityTransitIndex, String>((ref, city) async {
  try {
    final text = await rootBundle.loadString('supabase/seed/derived/city_transit_${city.toLowerCase()}.json');
    return CityTransitIndex.fromJson(jsonDecode(text) as Map<String, dynamic>);
  } catch (_) {
    return CityTransitIndex.empty;
  }
});
