/// Helper waktu murni (tanpa Flutter). Di domain, jam = menit sejak tengah malam.
abstract final class Clock {
  static const minutesPerDay = 24 * 60;

  /// `"06:25:00"` atau `"06:25"` dari Postgres `time` menjadi 385.
  static int parseDbTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      throw FormatException('Format jam tidak dikenal: $value');
    }
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// 385 menjadi `"06:25:00"` untuk dikirim ke Postgres.
  static String toDbTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  /// 565 menjadi `"09.25"` (format tampil, docs/DESIGN_SYSTEM.md).
  static String format(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }

  /// 45 menjadi `"45 mnt"`, 130 menjadi `"2 j 10 mnt"`, 120 menjadi `"2 j"`.
  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m mnt';
    if (m == 0) return '$h j';
    return '$h j $m mnt';
  }
}
