import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/seed_csv.dart';

void main() {
  test('kutip ganda dan koma dalam sel', () {
    final t = parseCsv('a,b\n"x,1","kutip ""dalam"""\n');
    expect(t.header, ['a', 'b']);
    expect(t.rows.single.cells, ['x,1', 'kutip "dalam"']);
  });

  test('baris baru dalam kutip tetap satu baris', () {
    final t = parseCsv('a,b\n"dua\nbaris",2\n3,4\n');
    expect(t.rows.length, 2);
    expect(t.rows.first.cells.first, 'dua\nbaris');
    expect(t.rows[1].line, 4);
  });

  test('nomor baris untuk laporan error', () {
    final t = parseCsv('a\n1\n2\n3\n');
    expect(t.rows.map((r) => r.line), [2, 3, 4]);
  });

  test('baris kosong dilewati', () {
    final t = parseCsv('a\n1\n\n2\n');
    expect(t.rows.length, 2);
  });
}