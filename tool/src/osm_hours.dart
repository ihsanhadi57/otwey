/// Parser `opening_hours` OpenStreetMap untuk pola umum saja.
///
/// Didukung: `24/7`, dan aturan `Mo-Fr 09:00-17:00; Sa,Su 10:00-14:00,16:00-20:00`.
/// Pola lain (PH, bulan, "sunrise", komentar) membuat hasil null, supaya tidak
/// ada jam buka tebakan. Jam lewat tengah malam dipotong ke 23:59.
library;

const _days = {'Mo': 1, 'Tu': 2, 'We': 3, 'Th': 4, 'Fr': 5, 'Sa': 6, 'Su': 7};

/// Satu baris jam buka: hari ISO, menit buka, menit tutup.
typedef OsmHour = ({int day, int open, int close});

List<OsmHour>? parseOsmOpeningHours(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value == '24/7') {
    return [for (var d = 1; d <= 7; d++) (day: d, open: 0, close: 23 * 60 + 59)];
  }
  final byDay = <int, List<(int, int)>>{};
  for (final rule in value.split(';')) {
    final r = rule.trim();
    if (r.isEmpty) continue;
    if (RegExp(r'^PH\s+off$').hasMatch(r)) continue;
    final m = RegExp(r'^([A-Za-z,\- ]+?)\s+(off|closed|[\d:,\- ]+)$').firstMatch(r);
    // Tanpa hari = berlaku tiap hari ("08:00-22:00").
    final daysPart = m?.group(1) ?? (RegExp(r'^[\d:,\- ]+$').hasMatch(r) ? 'Mo-Su' : null);
    final timesPart = m?.group(2) ?? (daysPart != null ? r : null);
    if (daysPart == null || timesPart == null) return null;
    final days = _parseDays(daysPart);
    if (days == null) return null;
    if (timesPart == 'off' || timesPart == 'closed') {
      for (final d in days) {
        byDay[d] = [];
      }
      continue;
    }
    final spans = _parseSpans(timesPart);
    if (spans == null) return null;
    for (final d in days) {
      byDay[d] = spans; // aturan belakangan menimpa yang depan, sesuai spesifikasi OSM
    }
  }
  if (byDay.isEmpty) return null;
  final out = <OsmHour>[];
  for (final d in byDay.keys.toList()..sort()) {
    for (final (o, c) in byDay[d]!) {
      out.add((day: d, open: o, close: c));
    }
  }
  return out.isEmpty ? null : out;
}

List<int>? _parseDays(String s) {
  final out = <int>{};
  for (final part in s.replaceAll(' ', '').split(',')) {
    final range = part.split('-');
    final a = _days[range.first];
    final b = range.length == 2 ? _days[range.last] : a;
    if (a == null || b == null || range.length > 2) return null;
    if (a <= b) {
      for (var d = a; d <= b; d++) {
        out.add(d);
      }
    } else {
      // Rentang melingkar, misalnya Sa-Mo.
      for (var d = a; d <= 7; d++) {
        out.add(d);
      }
      for (var d = 1; d <= b; d++) {
        out.add(d);
      }
    }
  }
  return out.toList()..sort();
}

List<(int, int)>? _parseSpans(String s) {
  final out = <(int, int)>[];
  for (final span in s.replaceAll(' ', '').split(',')) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})$').firstMatch(span);
    if (m == null) return null;
    final open = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    var close = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    if (open >= 24 * 60) return null;
    if (close >= 24 * 60 || close <= open) close = 23 * 60 + 59;
    out.add((open, close));
  }
  return out;
}
