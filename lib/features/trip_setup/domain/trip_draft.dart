import '../../planner/domain/leg_mode.dart';
import 'origin_point.dart';
import 'plan_pin.dart';
import 'travel_mode.dart';
import 'trip_pace.dart';
import 'trip_direction.dart';
import 'vibe_catalog.dart';

/// Isi form rencana trip. Jam dalam menit sejak tengah malam.
class TripDraft {
  const TripDraft({
    required this.direction,
    required this.travelDate,
    required this.earliestDeparture,
    required this.latestReturn,
    this.origin,
    this.originLabel,
    this.originLat,
    this.originLng,
    this.arrivalStationCode,
    this.pins = const [],
    this.tripTypeCode,
    this.categoryCodes = const [],
    this.budget,
    this.withKids = false,
    this.travelMode = TravelMode.campur,
    this.maxStops = 4,
    this.excludedPlaceIds = const [],
    this.keptPlaceIds,
    this.returnDepartureCap,
    this.stayOverrides = const {},
    this.legModes = const {},
  });

  /// Draft awal: besok, 07.00 sampai 21.00, Kulineran, Hemat, pindah Campur.
  factory TripDraft.initial(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return TripDraft(
      direction: TripDirection.jakartaToBandung,
      travelDate: tomorrow,
      earliestDeparture: 7 * 60,
      latestReturn: 21 * 60,
      tripTypeCode: 'kulineran',
      categoryCodes: const ['makanan_berat', 'jajanan', 'oleh_oleh'],
      budget: 'murah',
    );
  }

  final TripDirection direction;
  final DateTime travelDate;
  final int earliestDeparture;
  final int latestReturn;

  /// Titik berangkat yang dipilih user di kota asal.
  final OriginPoint? origin;
  final String? originLabel;
  final double? originLat;
  final double? originLng;
  final String? arrivalStationCode;
  final List<PlanPin> pins;
  final String? tripTypeCode;
  final List<String> categoryCodes;

  /// `murah`, `sedang`, atau `mahal` (enum `price_range`).
  final String? budget;
  final bool withKids;
  final TravelMode travelMode;

  /// Batas tempat rekomendasi planner (lihat [TripPace]). Pin user tidak dihitung.
  final int maxStops;

  /// Tempat yang dihapus user dari hasil. Planner tidak memakainya lagi.
  final List<String> excludedPlaceIds;

  /// Rekomendasi yang dipertahankan setelah user mengedit hasil, urut jam.
  /// Planner menyisipkannya lebih dulu supaya hasil tidak teracak ulang.
  /// Null berarti belum ada edit: planner memilih bebas.
  final List<String>? keptPlaceIds;

  /// Batas jam berangkat kereta pulang (menit), dari aksi "Pulang lebih awal".
  final int? returnDepartureCap;

  /// Lama kunjungan pilihan user (menit), per id tempat atau id pin.
  final Map<String, int> stayOverrides;

  /// Moda pilihan user per perpindahan ([legKey]). Planner menjadwalkan ulang
  /// dengan moda ini supaya jam tetap bisa dijalani.
  final Map<String, LegMode> legModes;

  TripPace? get pace => TripPace.of(maxStops);

  String get originCity => direction.originCity;
  String get destinationCity => direction.destinationCity;

  TripVibe get vibe => VibeCatalog.byCode(tripTypeCode ?? 'kulineran');

  /// Total menit tujuan berjam tetap (meeting, janji).
  int get fixedPinMinutes => pins
      .where((p) => p.isFixedTime)
      .fold(0, (sum, p) => sum + p.stayMinutes);

  TripDraft copyWith({
    TripDirection? direction,
    DateTime? travelDate,
    int? earliestDeparture,
    int? latestReturn,
    OriginPoint? origin,
    String? originLabel,
    double? originLat,
    double? originLng,
    String? arrivalStationCode,
    List<PlanPin>? pins,
    String? tripTypeCode,
    List<String>? categoryCodes,
    String? budget,
    bool? withKids,
    TravelMode? travelMode,
    int? maxStops,
    List<String>? excludedPlaceIds,
    List<String>? keptPlaceIds,
    int? returnDepartureCap,
    Map<String, int>? stayOverrides,
    Map<String, LegMode>? legModes,
    bool clearOrigin = false,
    bool clearEdits = false,
  }) =>
      TripDraft(
        direction: direction ?? this.direction,
        travelDate: travelDate ?? this.travelDate,
        earliestDeparture: earliestDeparture ?? this.earliestDeparture,
        latestReturn: latestReturn ?? this.latestReturn,
        origin: clearOrigin ? null : (origin ?? this.origin),
        originLabel: clearOrigin ? null : (originLabel ?? this.originLabel),
        originLat: clearOrigin ? null : (originLat ?? this.originLat),
        originLng: clearOrigin ? null : (originLng ?? this.originLng),
        arrivalStationCode: clearOrigin ? null : (arrivalStationCode ?? this.arrivalStationCode),
        pins: pins ?? this.pins,
        tripTypeCode: tripTypeCode ?? this.tripTypeCode,
        categoryCodes: categoryCodes ?? this.categoryCodes,
        budget: budget ?? this.budget,
        withKids: withKids ?? this.withKids,
        travelMode: travelMode ?? this.travelMode,
        maxStops: maxStops ?? this.maxStops,
        excludedPlaceIds: clearEdits ? const [] : (excludedPlaceIds ?? this.excludedPlaceIds),
        keptPlaceIds: clearEdits ? null : (keptPlaceIds ?? this.keptPlaceIds),
        returnDepartureCap: clearEdits ? null : (returnDepartureCap ?? this.returnDepartureCap),
        stayOverrides: clearEdits ? const {} : (stayOverrides ?? this.stayOverrides),
        legModes: clearEdits ? const {} : (legModes ?? this.legModes),
      );
}
