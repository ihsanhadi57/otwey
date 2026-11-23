/// Parser CSV murni (RFC 4180): koma, kutip ganda, dan baris baru dalam kutip.
/// Dipakai importer seed (tool/) dan repository mode seed supaya satu sumber.
library;

class CsvRow {
  const CsvRow(this.line, this.cells);

  /// Nomor baris file (1-based, header = 1) tempat baris ini mulai.
  final int line;
  final List<String> cells;
}

class CsvTable {
  const CsvTable(this.header, this.rows);

  final List<String> header;
  final List<CsvRow> rows;

  int? column(String name) {
    final i = header.indexOf(name);
    return i < 0 ? null : i;
  }

  String cell(CsvRow row, String name) {
    final i = column(name);
    if (i == null || i >= row.cells.length) return '';
    return row.cells[i].trim();
  }
}

CsvTable parseCsv(String source) {
  final rows = <List<String>>[];
  final starts = <int>[];
  var field = StringBuffer();
  var row = <String>[];
  var inQuotes = false;
  var line = 1;
  var rowStart = 1;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field = StringBuffer();
  }

  void endRow() {
    endField();
    if (row.length > 1 || row.first.trim().isNotEmpty) {
      rows.add(row);
      starts.add(rowStart);
    }
    row = <String>[];
    rowStart = line + 1;
  }

  while (i < source.length) {
    final ch = source[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      if (ch == '\n') line++;
      field.write(ch);
      i++;
      continue;
    }
    switch (ch) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\n':
        endRow();
        line++;
      case '\r':
        break;
      default:
        field.write(ch);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();

  if (rows.isEmpty) return const CsvTable([], []);
  final header = rows.first.map((c) => c.trim()).toList();
  final body = <CsvRow>[];
  for (var r = 1; r < rows.length; r++) {
    body.add(CsvRow(starts[r], rows[r]));
  }
  return CsvTable(header, body);
}