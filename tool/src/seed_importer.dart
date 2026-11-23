/// Inti importer seed: validasi CSV lalu hasilkan SQL. Dipakai CLI dan unit test.
library;

import 'package:otwey/core/utils/seed_validate.dart';

import 'seed_sql.dart';

class ImportReport {
  const ImportReport({this.sql, this.issues = const [], this.warnings = const []});

  /// Null kalau ada baris gagal: seed.sql tidak boleh ditulis setengah jadi.
  final String? sql;
  final List<SeedIssue> issues;
  final List<SeedIssue> warnings;

  bool get ok => sql != null;
}

ImportReport runImport(Map<String, String> files) {
  final data = validateSeed(files);
  if (!data.ok) return ImportReport(issues: data.issues, warnings: data.warnings);
  return ImportReport(sql: emitSeedSql(data), warnings: data.warnings);
}