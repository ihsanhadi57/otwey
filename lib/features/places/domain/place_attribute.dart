/// Label atribut tempat. Sama dengan seed `mst_attribute`.
///
/// TODO(hadi): baca dari `mst_attribute` lewat repository.
abstract final class PlaceAttribute {
  static const _labels = {
    'indoor': 'Indoor',
    'outdoor': 'Outdoor',
    'cocok_hujan': 'Aman pas hujan',
    'ramah_anak': 'Ramah bocil',
    'halal': 'Halal',
    'legendaris': 'Legend',
    'spot_foto': 'Spot foto',
    'budget_murah': 'Hemat',
    'budget_sedang': 'Sedang',
    'budget_mahal': 'Sultan',
  };

  /// Atribut yang bisa dipakai menyaring di Jelajah.
  static const filterable = ['halal', 'indoor', 'outdoor', 'cocok_hujan', 'ramah_anak', 'legendaris', 'spot_foto'];

  static String label(String code) => _labels[code] ?? code;

  /// Atribut non budget, dalam bentuk label. Budget ditampilkan terpisah.
  static List<String> labelsOf(List<String> codes) => [
        for (final c in codes)
          if (!c.startsWith('budget_') && _labels[c] != null) _labels[c]!,
      ];
}
