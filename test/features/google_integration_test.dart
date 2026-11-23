import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/maps_launcher.dart';
import 'package:otwey/features/places/domain/google_place_details.dart';
import 'package:otwey/features/planner/domain/transit_route.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/google/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('TransitRoute', () {
    test('parse payload transit-route', () {
      final r = TransitRoute.fromJson(_fixture('transit_route'))!;
      expect(r.minutes, 41);
      expect(r.distanceMeters, 9120);
      expect(r.steps, hasLength(4));
      expect(r.hasTransit, isTrue);
      final mrt = r.steps[1];
      expect(mrt.mode, TransitMode.subway);
      expect(mrt.badge, 'M');
      expect(mrt.colorArgb, 0xFF0057A8);
      expect(mrt.from, 'Blok M BCA');
      expect(mrt.stops, 9);
      // 01:07 UTC = 08:07 WIB.
      expect(mrt.departAt, 8 * 60 + 7);
      expect(mrt.arriveAt, 8 * 60 + 25);
      final bus = r.steps[2];
      expect(bus.mode, TransitMode.bus);
      expect(bus.departAt, 8 * 60 + 30);
      expect(bus.colorArgb, isNull);
      expect(r.rides.map((s) => s.mode), [TransitMode.subway, TransitMode.bus]);
    });

    test('tanpa rute atau cuma jalan kaki = null', () {
      expect(TransitRoute.fromJson({'minutes': null, 'steps': []}), isNull);
      expect(TransitRoute.fromJson({'error': {'code': 'quota'}}), isNull);
      expect(TransitRoute.fromJson(null), isNull);
      expect(
        TransitRoute.fromJson({
          'minutes': 12,
          'steps': [
            {'mode': 'walk', 'minutes': 12},
          ],
        }),
        isNull,
      );
    });

    test('moda tak dikenal jadi other, menit total dihitung kalau kosong', () {
      final r = TransitRoute.fromJson({
        'steps': [
          {'mode': 'walk', 'minutes': 3},
          {'mode': 'ferry', 'minutes': 10},
        ],
      })!;
      expect(r.steps[1].mode, TransitMode.other);
      expect(r.minutes, 13);
    });

    test('wibIso dan wibMinutes', () {
      expect(wibIso(DateTime(2026, 11, 25), 8 * 60 + 5), '2026-11-25T08:05:00+07:00');
      expect(wibMinutes('2026-11-25T08:05:00+07:00'), 8 * 60 + 5);
      expect(wibMinutes('2026-11-24T23:30:00Z'), 6 * 60 + 30);
      expect(wibMinutes('bukan jam'), isNull);
    });
  });

  group('GooglePlaceDetails', () {
    test('parse respon place-details', () {
      final d = GooglePlaceDetails.fromJson(_fixture('place_details'));
      expect(d.rating, 4.6);
      expect(d.ratingCount, 3120);
      expect(d.status, BusinessStatus.operational);
      expect(d.isClosed, isFalse);
      expect(d.openNow, isTrue);
      expect(d.weekdayDescriptions.first, 'Senin: Tutup');
      final tue = d.openingHours.where((h) => h.dayOfWeek == 2).single;
      expect((tue.open, tue.close), (9 * 60, 15 * 60));
      // Minggu Google (0) jadi hari ISO 7.
      expect(d.openingHours.any((h) => h.dayOfWeek == 7 && h.open == 9 * 60 + 30), isTrue);
      // Jumat 18.00 sampai Sabtu 02.00 dipecah di tengah malam.
      expect(d.openingHours.any((h) => h.dayOfWeek == 5 && h.open == 18 * 60 && h.close == 24 * 60), isTrue);
      expect(d.openingHours.any((h) => h.dayOfWeek == 6 && h.open == 0 && h.close == 2 * 60), isTrue);
    });

    test('buka 24 jam (tanpa close) dan status tutup', () {
      final hours = periodsToHours([
        {'open': {'day': 0, 'hour': 0, 'minute': 0}},
      ]);
      expect(hours, hasLength(7));
      expect(hours.every((h) => h.open == 0 && h.close == 24 * 60), isTrue);
      final d = GooglePlaceDetails.fromJson({'businessStatus': 'CLOSED_PERMANENTLY'});
      expect(d.isClosed, isTrue);
      expect(d.rating, isNull);
      expect(d.openingHours, isEmpty);
    });
  });

  group('directionsUri', () {
    test('dengan place_id: nama + destination_place_id', () {
      final u = directionsUri(-6.18, 106.83,
          mode: DirectionsMode.transit, label: 'Gedung Joang 45', placeId: 'ChIJabc');
      expect(u.host, 'www.google.com');
      expect(u.queryParameters['api'], '1');
      expect(u.queryParameters['destination'], 'Gedung Joang 45');
      expect(u.queryParameters['destination_place_id'], 'ChIJabc');
      expect(u.queryParameters['travelmode'], 'transit');
    });

    test('tanpa place_id: koordinat, tanpa parameter place_id', () {
      final u = directionsUri(-6.18, 106.83, label: 'Gedung Joang 45');
      expect(u.queryParameters['destination'], '-6.18,106.83');
      expect(u.queryParameters.containsKey('destination_place_id'), isFalse);
      expect(u.queryParameters['travelmode'], 'driving');
    });

    test('mapsSearchUri memakai query_place_id', () {
      final u = mapsSearchUri(-6.18, 106.83, label: 'Gedung Joang 45', placeId: 'ChIJabc');
      expect(u.queryParameters['query'], 'Gedung Joang 45');
      expect(u.queryParameters['query_place_id'], 'ChIJabc');
    });
  });
}
