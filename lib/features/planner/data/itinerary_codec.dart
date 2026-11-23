import '../domain/itinerary.dart';
import '../domain/leg_mode.dart';

/// Serialisasi itinerary ke JSON untuk disimpan di `trx_plan.itinerary_json`
/// atau perangkat. Domain tetap murni; codec ini tinggal di lapisan data.
Map<String, dynamic> itineraryToJson(Itinerary it) => {
      'originCity': it.originCity,
      'destinationCity': it.destinationCity,
      'originLabel': it.originLabel,
      'date': it.date.toIso8601String(),
      'vibeLabel': it.vibeLabel,
      'budgetLabel': it.budgetLabel,
      'freeMinutes': it.freeMinutes,
      'latestReturn': it.latestReturn,
      'status': it.status.name,
      'route': [for (final p in it.route) _routePointToJson(p)],
      'returnDeparture': it.returnDeparture,
      'earlierReturnDeparture': it.earlierReturnDeparture,
      'moreStopsAvailable': it.moreStopsAvailable,
      'droppedPlaceNames': it.droppedPlaceNames,
      'droppedPinNames': it.droppedPinNames,
      'entries': [for (final e in it.entries) _entryToJson(e)],
    };

Itinerary itineraryFromJson(Map<String, dynamic> json) => Itinerary(
      originCity: json['originCity'] as String,
      destinationCity: json['destinationCity'] as String,
      originLabel: json['originLabel'] as String,
      date: DateTime.parse(json['date'] as String),
      vibeLabel: json['vibeLabel'] as String,
      budgetLabel: json['budgetLabel'] as String,
      freeMinutes: json['freeMinutes'] as int,
      latestReturn: json['latestReturn'] as int,
      status: PlanStatus.values.byName(json['status'] as String),
      route: [
        for (final p in (json['route'] as List? ?? const []))
          _routePointFromJson(p as Map<String, dynamic>),
      ],
      returnDeparture: json['returnDeparture'] as int?,
      earlierReturnDeparture: json['earlierReturnDeparture'] as int?,
      moreStopsAvailable: json['moreStopsAvailable'] as bool? ?? false,
      droppedPlaceNames: (json['droppedPlaceNames'] as List? ?? const []).cast<String>(),
      droppedPinNames: (json['droppedPinNames'] as List? ?? const []).cast<String>(),
      entries: [
        for (final e in (json['entries'] as List? ?? const []))
          _entryFromJson(e as Map<String, dynamic>),
      ],
    );

Map<String, String> legChoicesToJson(Map<String, LegMode> choices) =>
    {for (final e in choices.entries) e.key: e.value.name};

Map<String, LegMode> legChoicesFromJson(Map<String, dynamic> json) =>
    {for (final e in json.entries) e.key: LegMode.values.byName(e.value as String)};

Map<String, dynamic> _routePointToJson(RoutePoint p) => {
      'lat': p.lat,
      'lng': p.lng,
      'kind': p.kind.name,
      'label': p.label,
      'number': p.number,
    };

RoutePoint _routePointFromJson(Map<String, dynamic> json) => RoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      kind: RoutePointKind.values.byName(json['kind'] as String),
      label: json['label'] as String,
      number: json['number'] as int?,
    );

Map<String, dynamic> _entryToJson(TimelineEntry e) => switch (e) {
      final PointEntry p => {
          'type': 'point',
          'time': p.time,
          'kind': p.kind.name,
          'title': p.title,
          'subtitle': p.subtitle,
          'lat': p.lat,
          'lng': p.lng,
        },
      final TrainEntry t => {
          'type': 'train',
          'departure': t.departure,
          'arrival': t.arrival,
          'from': t.from,
          'to': t.to,
          'bufferMinutes': t.bufferMinutes,
          'isFeeder': t.isFeeder,
        },
      final LegEntry l => {
          'type': 'leg',
          'id': l.id,
          'start': l.start,
          'destination': l.destination,
          'distanceKm': l.distanceKm,
          'ojol': _optionToJson(l.ojol),
          'transum': l.transum == null ? null : _optionToJson(l.transum!),
          'transumKind': l.transumKind.name,
          'steps': [for (final s in l.steps) _stepToJson(s)],
          'recommended': l.recommended.name,
          'fromLat': l.fromLat,
          'fromLng': l.fromLng,
          'toLat': l.toLat,
          'toLng': l.toLng,
        },
      final WalkEntry w => {'type': 'walk', 'minutes': w.minutes},
      final StopEntry s => {
          'type': 'stop',
          'time': s.time,
          'number': s.number,
          'placeId': s.placeId,
          'title': s.title,
          'categoryCode': s.categoryCode,
          'categoryLabel': s.categoryLabel,
          'minutes': s.minutes,
          'optional': s.optional,
          'reason': s.reason,
          'lat': s.lat,
          'lng': s.lng,
          'pinId': s.pinId,
        },
      final FreeTimeEntry f => {
          'type': 'free',
          'time': f.time,
          'minutes': f.minutes,
          'beforeReturn': f.beforeReturn,
        },
      final LockedEntry k => {
          'type': 'locked',
          'start': k.start,
          'end': k.end,
          'title': k.title,
          'purposeLabel': k.purposeLabel,
          'lat': k.lat,
          'lng': k.lng,
        },
    };

TimelineEntry _entryFromJson(Map<String, dynamic> json) => switch (json['type'] as String) {
      'point' => PointEntry(
          time: json['time'] as int,
          kind: PointKind.values.byName(json['kind'] as String),
          title: json['title'] as String,
          subtitle: json['subtitle'] as String?,
          lat: (json['lat'] as num?)?.toDouble(),
          lng: (json['lng'] as num?)?.toDouble(),
        ),
      'train' => TrainEntry(
          departure: json['departure'] as int,
          arrival: json['arrival'] as int,
          from: json['from'] as String,
          to: json['to'] as String,
          bufferMinutes: json['bufferMinutes'] as int?,
          isFeeder: json['isFeeder'] as bool? ?? false,
        ),
      'leg' => LegEntry(
          id: json['id'] as String,
          start: json['start'] as int,
          destination: json['destination'] as String,
          distanceKm: (json['distanceKm'] as num).toDouble(),
          ojol: _optionFromJson(json['ojol'] as Map<String, dynamic>),
          transum: json['transum'] == null
              ? null
              : _optionFromJson(json['transum'] as Map<String, dynamic>),
          transumKind: TransitKind.values.byName(json['transumKind'] as String),
          steps: [
            for (final s in (json['steps'] as List? ?? const []))
              _stepFromJson(s as Map<String, dynamic>),
          ],
          recommended: LegMode.values.byName(json['recommended'] as String),
          fromLat: (json['fromLat'] as num?)?.toDouble(),
          fromLng: (json['fromLng'] as num?)?.toDouble(),
          toLat: (json['toLat'] as num?)?.toDouble(),
          toLng: (json['toLng'] as num?)?.toDouble(),
        ),
      'walk' => WalkEntry(minutes: json['minutes'] as int),
      'stop' => StopEntry(
          time: json['time'] as int,
          number: json['number'] as int,
          placeId: json['placeId'] as String,
          title: json['title'] as String,
          categoryCode: json['categoryCode'] as String,
          categoryLabel: json['categoryLabel'] as String,
          minutes: json['minutes'] as int,
          optional: json['optional'] as bool? ?? false,
          reason: json['reason'] as String?,
          lat: (json['lat'] as num?)?.toDouble(),
          lng: (json['lng'] as num?)?.toDouble(),
          pinId: json['pinId'] as String?,
        ),
      'free' => FreeTimeEntry(
          time: json['time'] as int,
          minutes: json['minutes'] as int,
          beforeReturn: json['beforeReturn'] as bool? ?? false,
        ),
      'locked' => LockedEntry(
          start: json['start'] as int,
          end: json['end'] as int,
          title: json['title'] as String,
          purposeLabel: json['purposeLabel'] as String,
          lat: (json['lat'] as num?)?.toDouble(),
          lng: (json['lng'] as num?)?.toDouble(),
        ),
      _ => throw FormatException('Jenis entry tidak dikenal: ${json['type']}'),
    };

Map<String, dynamic> _optionToJson(LegOption o) => {
      'minutes': o.minutes,
      'costRupiah': o.costRupiah,
    };

LegOption _optionFromJson(Map<String, dynamic> json) => LegOption(
      minutes: json['minutes'] as int,
      costRupiah: json['costRupiah'] as int,
    );

Map<String, dynamic> _stepToJson(TransitStep s) => {
      'kind': s.kind.name,
      'text': s.text,
      'corridor': s.corridor,
      'tone': s.tone.name,
    };

TransitStep _stepFromJson(Map<String, dynamic> json) => TransitStep(
      kind: TransitKind.values.byName(json['kind'] as String),
      text: json['text'] as String,
      corridor: json['corridor'] as String?,
      tone: CorridorTone.values.byName(json['tone'] as String? ?? 'rail'),
    );