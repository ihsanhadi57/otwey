/// Importer seed OTWEY: baca supabase/seed/*.csv, validasi, tulis supabase/seed.sql.
///
/// Jalankan: dart run tool/seed_import.dart
/// Baris gagal atau template "(isi)" dilaporkan per baris dan seed.sql tidak ditulis.
library;

import 'dart:io';

import 'package:otwey/core/utils/seed_validate.dart';

import 'src/seed_importer.dart';

Future<void> main(List<String> args) async {
  final dir = Directory(args.isNotEmpty ? args.first : 'supabase/seed');
  if (!dir.existsSync()) {
    stderr.writeln('Folder tidak ada: ${dir.path}');
    exitCode = 1;
    return;
  }
  final files = <String, String>{};
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.csv')) continue;
    final name = f.uri.pathSegments.last.replaceAll('.csv', '');
    if (!seedFileNames.contains(name)) continue;
    files[name] = f.readAsStringSync();
  }
  if (files.isEmpty) {
    stderr.writeln('Tidak ada CSV yang dikenali di ${dir.path}. Nama yang dikenali: ${seedFileNames.join(', ')}.');
    exitCode = 1;
    return;
  }

  final report = runImport(files);
  for (final w in report.warnings) {
    stdout.writeln('peringatan $w');
  }
  if (!report.ok) {
    stderr.writeln('${report.issues.length} masalah ditemukan, seed.sql TIDAK ditulis:');
    for (final i in report.issues) {
      stderr.writeln('  $i');
    }
    stderr.writeln('Isi dulu CSV di ${dir.path} dengan data bersumber, lalu jalankan ulang.');
    exitCode = 1;
    return;
  }
  File('supabase/seed.sql').writeAsStringSync(report.sql!);
  stdout.writeln('seed.sql ditulis (${report.sql!.split('\n').length} baris). Aman dijalankan berulang (upsert).');
}