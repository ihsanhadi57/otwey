import 'place.dart';

/// Status usaha dari Google Places.
enum BusinessStatus {
  operational,
  closedTemporarily,
  closedPermanently,
  unknown;

  static BusinessStatus fromJson(Object? v) => switch (v) {
        'OPERATIONAL' => operational,
        'CLOSED_TEMPORARILY' => closedTemporarily,
        'CLOSED_PERMANENTLY' => closedPermanently,
        _ => unknown,
      };
}

/// Detail langsung dari Edge Function `place-details` (Google Places API).
/// Tidak disimpan permanen di aplikasi, sesuai ketentuan Google.
class GooglePlaceDetails {
  const GooglePlaceDetails({
    required this.status,
    required this.openingHours,
    required this.weekdayDescriptions,
    this.rating,
    this.ratingCount,
    this.openNow,
    this.mapsUri,
  });

  final double? rating;
  final int? ratingCount;
  final BusinessStatus status;
  final bool? openNow;
  final String? mapsUri;

  /// Jam buka reguler, format sama dengan data seed (menit, hari ISO).
  final List<OpeningHour> openingHours;

  /// Teks jam buka per hari dari Google, misalnya "Senin: 08.00–17.00".
  final List<String> weekdayDescriptions;

  bool get isClosed => status == BusinessStatus.closedPermanently || status == BusinessStatus.closedTemporarily;

  factory GooglePlaceDetails.fromJson(Map<String, dynamic> j) {
    final regular = j['regularOpeningHours'];
    final current = j['currentOpeningHours'];
    return GooglePlaceDetails(
      rating: (j['rating'] as num?)?.toDouble(),
      ratingCount: (j['userRatingCount'] as num?)?.round(),
      status: BusinessStatus.fromJson(j['businessStatus']),
      openNow: current is Map ? current['openNow'] as bool? : null,
      mapsUri: j['googleMapsUri'] as String?,
      openingHours: regular is Map ? periodsToHours(regular['periods']) : const [],
      weekdayDescriptions: regular is Map && regular['weekdayDescriptions'] is List
          ? (regular['weekdayDescriptions'] as List).whereType<String>().toList()
          : const [],
    );
  }
}

/// Ubah `periods` Google (hari 0 = Minggu) ke [OpeningHour] (hari ISO 1–7).
///
/// * Tanpa `close`: buka 24 jam, jadi 00.00–24.00 setiap hari.
/// * Lewat tengah malam (close di hari berikutnya): dipotong sampai 24.00
///   di hari buka, dan bagian setelah tengah malam ditambahkan di hari berikutnya.
List<OpeningHour> periodsToHours(Object? periods) {
  if (periods is! List) return const [];
  int iso(int googleDay) => googleDay == 0 ? 7 : googleDay;
  int minutes(Map p) => ((p['hour'] as num?) ?? 0).toInt() * 60 + ((p['minute'] as num?) ?? 0).toInt();
  const endOfDay = 24 * 60;
  final out = <OpeningHour>[];
  for (final p in periods) {
    if (p is! Map || p['open'] is! Map) continue;
    final open = p['open'] as Map;
    final openDay = (open['day'] as num?)?.toInt();
    if (openDay == null) continue;
    final close = p['close'];
    if (close is! Map) {
      for (var d = 1; d <= 7; d++) {
        out.add(OpeningHour(dayOfWeek: d, open: 0, close: endOfDay));
      }
      return out;
    }
    final closeDay = (close['day'] as num?)?.toInt() ?? openDay;
    final from = minutes(open);
    final to = minutes(close);
    if (closeDay == openDay && to > from) {
      out.add(OpeningHour(dayOfWeek: iso(openDay), open: from, close: to));
    } else {
      out.add(OpeningHour(dayOfWeek: iso(openDay), open: from, close: endOfDay));
      if (to > 0) out.add(OpeningHour(dayOfWeek: iso(closeDay), open: 0, close: to));
    }
  }
  return out;
}
