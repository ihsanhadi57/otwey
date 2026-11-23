/// Format ongkos ringkas: 0 = "Gratis", 32000 = "± Rp32rb", 4900 = "Rp4.900".
abstract final class Rupiah {
  static String short(int value, {String free = 'Gratis'}) {
    if (value == 0) return free;
    if (value < 10000) {
      final s = value.toString();
      return s.length > 3 ? 'Rp${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}' : 'Rp$s';
    }
    return '± Rp${(value / 1000).round()}rb';
  }
}
