import 'package:url_launcher/url_launcher.dart';

/// Moda petunjuk arah di aplikasi peta.
enum DirectionsMode { driving, transit, walking, twoWheeler }

/// URL petunjuk arah Google Maps (Maps URLs, tanpa API key).
///
/// Kalau [placeId] Google ada, tujuan dikirim sebagai nama + `destination_place_id`
/// sehingga Google Maps membuka tempatnya (nama, foto, ulasan), bukan titik
/// koordinat. Tanpa [placeId], koordinat tetap dipakai karena paling akurat:
/// nama saja bisa salah tempat (cabang lain, nama mirip).
Uri directionsUri(
  double lat,
  double lng, {
  DirectionsMode mode = DirectionsMode.driving,
  String? label,
  String? placeId,
}) {
  final travel = switch (mode) {
    DirectionsMode.driving => 'driving',
    DirectionsMode.transit => 'transit',
    DirectionsMode.walking => 'walking',
    DirectionsMode.twoWheeler => 'two-wheeler',
  };
  final hasPlace = placeId != null && placeId.isNotEmpty;
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': hasPlace && label != null && label.isNotEmpty ? label : '$lat,$lng',
    'destination_place_id': ?(hasPlace ? placeId : null),
    'travelmode': travel,
  });
}

/// URL lihat lokasi di Google Maps. Dengan [placeId] membuka halaman tempatnya.
Uri mapsSearchUri(double lat, double lng, {String? label, String? placeId}) {
  final hasPlace = placeId != null && placeId.isNotEmpty;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': hasPlace && label != null && label.isNotEmpty ? label : '$lat,$lng',
    'query_place_id': ?(hasPlace ? placeId : null),
  });
}

/// Buka petunjuk arah di aplikasi peta bawaan (Google Maps kalau ada, selain
/// itu browser). Mengembalikan false kalau tidak ada aplikasi yang bisa membukanya.
Future<bool> openDirections(
  double lat,
  double lng, {
  DirectionsMode mode = DirectionsMode.driving,
  String? label,
  String? placeId,
}) =>
    launchUrl(directionsUri(lat, lng, mode: mode, label: label, placeId: placeId),
        mode: LaunchMode.externalApplication);

/// Buka titik di aplikasi peta (lihat lokasi, bukan rute).
Future<bool> openInMaps(double lat, double lng, {String? label, String? placeId}) =>
    launchUrl(mapsSearchUri(lat, lng, label: label, placeId: placeId), mode: LaunchMode.externalApplication);
