/// Format tanggal bahasa Indonesia tanpa paket intl.
abstract final class DateLabel {
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _daysLong = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  /// "Kam, 19 Nov"
  static String short(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  /// "Kamis, 19 Nov"
  static String long(DateTime d) => '${_daysLong[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  /// "KAM"
  static String dayCode(DateTime d) => _days[d.weekday - 1].toUpperCase();

  /// "Nov"
  static String month(DateTime d) => _months[d.month - 1];

  /// True kalau [d] adalah besok dari [now].
  static bool isTomorrow(DateTime d, DateTime now) {
    final t = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return d.year == t.year && d.month == t.month && d.day == t.day;
  }
}
