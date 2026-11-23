import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_validate.dart';

import '../../tool/src/seed_importer.dart';

Map<String, String> _fixtures(String dir) {
  final files = <String, String>{};
  for (final f in Directory('test/fixtures/$dir').listSync().whereType<File>()) {
    files[f.uri.pathSegments.last.replaceAll('.csv', '')] = f.readAsStringSync();
  }
  return files;
}

void main() {
  test('fixture valid menghasilkan seed.sql idempoten', () {
    final report = runImport(_fixtures('seed_valid'));
    expect(report.issues, isEmpty, reason: report.issues.join('\n'));
    expect(report.sql, isNotNull);
    final sql = report.sql!;
    expect(sql, contains('begin;'));
    expect(sql, contains('commit;'));
    expect(sql, contains('on conflict (code) do update'));
    expect(sql, contains('on conflict (train_no, direction, valid_from)'));
    expect(sql, contains('on conflict (source, source_ref) do update'));
    expect(sql, contains('on conflict (place_id, day_of_week, open_time)'));
    expect(sql, contains("'09:25'"));
    expect(runImport(_fixtures('seed_valid')).sql, sql);
  });

  test('template (isi) ditolak dengan pesan per baris', () {
    final files = _fixtures('seed_valid');
    files['whoosh_trip'] = files['whoosh_trip']!.replaceAll('fixture uji bukan jadwal resmi', 'jadwal resmi KCIC (isi)');
    final report = runImport(files);
    expect(report.ok, isFalse);
    expect(report.sql, isNull);
    expect(report.issues.length, 4);
    expect(report.issues.first.message, contains('template'));
    expect(report.issues.first.toString(), contains('whoosh_trip.csv:'));
  });

  test('file kosong atau hanya header ditolak', () {
    final report = runImport({'place': 'key,name,city,lat,lng\n'});
    expect(report.ok, isFalse);
    expect(report.issues.single.message, contains('kosong'));
  });

  test('koordinat di luar kota dilaporkan, bukan dilewati', () {
    final files = _fixtures('seed_valid');
    files['place'] = files['place']!.replaceAll('-6.9175,107.6091', '-6.9175,106.8091');
    final report = runImport(files);
    expect(report.ok, isFalse);
    expect(report.issues.any((i) => i.message.contains('di luar kota Bandung')), isTrue);
  });

  test('close sebelum open ditolak', () {
    final files = _fixtures('seed_valid');
    files['place_opening_hour'] = files['place_opening_hour']!.replaceAll('1,08:00,22:00', '1,22:00,08:00');
    final report = runImport(files);
    expect(report.ok, isFalse);
    expect(report.issues.any((i) => i.message.contains('close harus setelah open')), isTrue);
  });

  test('kategori dan stasiun tak dikenal ditolak', () {
    final files = _fixtures('seed_valid');
    files['place'] = files['place']!.replaceAll(',jajanan,', ',ngemil,');
    files['feeder_schedule'] = files['feeder_schedule']!.replaceAll(',PDL,BD,', ',XXX,BD,');
    final report = runImport(files);
    expect(report.ok, isFalse);
    expect(report.issues.any((i) => i.message.contains('kategori ngemil')), isTrue);
    expect(report.issues.any((i) => i.message.contains('XXX')), isTrue);
  });

  test('stop_seq tidak berurutan ditolak', () {
    final files = _fixtures('seed_valid');
    files['whoosh_trip'] = files['whoosh_trip']!.replaceAll('PDL,2,10:00', 'PDL,3,10:00');
    final report = runImport(files);
    expect(report.ok, isFalse);
    expect(report.issues.any((i) => i.message.contains('tidak berurutan')), isTrue);
  });

  test('koordinat stasiun kosong jadi peringatan TODO(hadi), bukan gagal', () {
    final files = _fixtures('seed_valid');
    files['station'] = 'code,name,city,type,lat,lng,source\nHLM,Stasiun Halim,Jakarta,whoosh,,,internal KCIC\n';
    final report = runImport(files);
    expect(report.ok, isTrue);
    expect(report.warnings.any((w) => w.message.contains('TODO(hadi)')), isTrue);
  });

  test('seed repo dan importer memakai validasi yang sama', () {
    final data = validateSeed(_fixtures('seed_valid'));
    expect(data.places.length, 2);
    expect(data.places.first.categories, ['jajanan']);
    expect(data.places.first.attributes, ['spot_foto', 'budget_murah']);
    expect(data.openingHours.length, 3);
    expect(data.whoosh.length, 4);
    expect(data.accessSteps.length, 2);
  });
}