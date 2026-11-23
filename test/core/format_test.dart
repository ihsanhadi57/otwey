import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/utils/date_label.dart';
import 'package:otwey/core/utils/rupiah.dart';

void main() {
  group('Rupiah.short', () {
    test('nol jadi Gratis', () => expect(Rupiah.short(0), 'Gratis'));
    test('di bawah 10 ribu ditulis lengkap', () => expect(Rupiah.short(4900), 'Rp4.900'));
    test('10 ribu ke atas dibulatkan ribuan', () => expect(Rupiah.short(32000), '± Rp32rb'));
  });

  group('DateLabel', () {
    final kamis = DateTime(2026, 11, 19);
    test('short', () => expect(DateLabel.short(kamis), 'Kam, 19 Nov'));
    test('long', () => expect(DateLabel.long(kamis), 'Kamis, 19 Nov'));
    test('isTomorrow', () {
      expect(DateLabel.isTomorrow(kamis, DateTime(2026, 11, 18, 22)), isTrue);
      expect(DateLabel.isTomorrow(kamis, DateTime(2026, 11, 19)), isFalse);
    });
  });
}
