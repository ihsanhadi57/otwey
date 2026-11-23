import 'dart:math' as math;
import 'dart:typed_data';

/// PostGIS `geography` dari PostgREST: GeoJSON Point, EWKB hex, atau WKT.
({double lat, double lng})? parseGeoPoint(Object? value) {
  if (value is Map && value['type'] == 'Point') {
    final c = value['coordinates'];
    if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
      return (lat: (c[1] as num).toDouble(), lng: (c[0] as num).toDouble());
    }
  }
  if (value is String) return _parseWkbHex(value) ?? _parseWkt(value);
  return null;
}

/// PostgREST mengirim kolom geography sebagai EWKB hex, misalnya
/// `0101000020E6100000...`: urutan byte, tipe (dengan flag SRID), SRID, x, y.
({double lat, double lng})? _parseWkbHex(String hex) {
  if (hex.length < 42 || hex.length.isOdd || !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(hex)) return null;
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  final data = ByteData.sublistView(bytes);
  final endian = bytes[0] == 1 ? Endian.little : Endian.big;
  final type = data.getUint32(1, endian);
  if (type & 0xFF != 1) return null; // bukan Point
  var offset = 5;
  if (type & 0x20000000 != 0) offset += 4; // lewati SRID
  if (bytes.length < offset + 16) return null;
  final x = data.getFloat64(offset, endian);
  final y = data.getFloat64(offset + 8, endian);
  if (x.isNaN || y.isNaN) return null;
  return (lat: y, lng: x);
}

/// `POINT(lng lat)`, boleh diawali `SRID=4326;`.
({double lat, double lng})? _parseWkt(String s) {
  final m = RegExp(r'POINT\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s*\)', caseSensitive: false).firstMatch(s);
  if (m == null) return null;
  return (lat: double.parse(m.group(2)!), lng: double.parse(m.group(1)!));
}

/// Jarak garis lurus (km) antara dua koordinat, rumus haversine.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(_rad(lat1)) * math.cos(_rad(lat2));
  return 2 * earthRadiusKm * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

double _rad(double deg) => deg * math.pi / 180;