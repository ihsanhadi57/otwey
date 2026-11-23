import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../places/domain/place.dart';

/// Satu hasil pencarian lokasi tujuan.
class AddressResult {
  const AddressResult({required this.name, required this.address, required this.lat, required this.lng, this.fromCatalog = false});

  final String name;
  final String address;
  final double lat;
  final double lng;

  /// True kalau dari katalog tempat OTWEY, false kalau dari OpenStreetMap.
  final bool fromCatalog;
}

final addressSearchProvider = Provider<AddressSearch>((ref) => AddressSearch(http.Client()));

/// Cari lokasi tujuan: katalog tempat OTWEY dulu (offline), lalu Nominatim
/// (OpenStreetMap) di sekitar kota tujuan. Nominatim hanya dipanggil saat user
/// menekan cari, sesuai kebijakan pemakaiannya (tanpa autocomplete).
///
/// TODO(hadi): pindahkan ke Edge Function + cache sebelum rilis publik, supaya
/// kuota Nominatim tidak dipakai langsung dari perangkat.
class AddressSearch {
  AddressSearch(this._client);

  final http.Client _client;

  static const _radiusDeg = 0.3;

  List<AddressResult> fromCatalog(String query, List<Place> places) {
    final q = _norm(query);
    if (q.length < 2) return const [];
    return [
      for (final p in places)
        if (_norm('${p.name} ${p.area ?? ''} ${p.address ?? ''}').contains(q))
          AddressResult(
            name: p.name,
            address: p.address ?? p.area ?? p.city,
            lat: p.lat,
            lng: p.lng,
            fromCatalog: true,
          ),
    ].take(5).toList();
  }

  Future<List<AddressResult>> online(String query, String city) async {
    if (query.trim().length < 3) return const [];
    final c = AppConfig.cityCenter(city);
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '8',
      'countrycodes': 'id',
      'accept-language': 'id',
      'bounded': '1',
      'viewbox': '${c.lng - _radiusDeg},${c.lat + _radiusDeg},${c.lng + _radiusDeg},${c.lat - _radiusDeg}',
    });
    final res = await _client
        .get(uri, headers: {'User-Agent': '${AppConfig.mapUserAgentPackage} (OTWEY hackathon)'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Nominatim ${res.statusCode}');
    final rows = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return [
      for (final r in rows)
        AddressResult(
          name: (r['name'] as String?)?.isNotEmpty == true
              ? r['name'] as String
              : (r['display_name'] as String).split(',').first,
          address: _shortAddress(r['display_name'] as String),
          lat: double.parse(r['lat'] as String),
          lng: double.parse(r['lon'] as String),
        ),
    ];
  }

  /// Nama jalan atau kawasan untuk satu koordinat (Nominatim reverse).
  /// Null kalau gagal; pemanggil memakai teks cadangan.
  Future<String?> reverse(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toStringAsFixed(5),
        'lon': lng.toStringAsFixed(5),
        'format': 'jsonv2',
        'zoom': '17',
        'accept-language': 'id',
      });
      final res = await _client
          .get(uri, headers: {'User-Agent': '${AppConfig.mapUserAgentPackage} (OTWEY hackathon)'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final display = (jsonDecode(res.body) as Map<String, dynamic>)['display_name'] as String?;
      return display == null ? null : _shortAddress(display);
    } catch (_) {
      return null;
    }
  }

  /// Alamat Nominatim panjang ("A, B, C, Kota, Provinsi, Kode pos, Indonesia").
  /// Ambil 3 bagian pertama supaya muat satu baris.
  static String _shortAddress(String display) => display.split(',').map((s) => s.trim()).take(3).join(', ');

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
