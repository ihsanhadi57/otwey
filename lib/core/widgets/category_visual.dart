import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'otw_icon.dart';

/// Ikon dan warna untuk kode vibes (`mst_trip_type`) dan kategori (`mst_category`).
/// Dipakai lintas fitur: beranda, rencana, hasil, jelajah, wishlist.
abstract final class CategoryVisual {
  static OtwIcon icon(String code) => switch (code) {
        'kulineran' => OtwIcon.bowl,
        'alam' => OtwIcon.mountain,
        'budaya' || 'sejarah_budaya' || 'seni_kreatif' => OtwIcon.city,
        'belanja' => OtwIcon.bag,
        'keluarga' => OtwIcon.family,
        'campuran' => OtwIcon.mix,
        'makanan_berat' || 'makanan_barat' => OtwIcon.rice,
        'jajanan' => OtwIcon.sate,
        'manis' => OtwIcon.icecream,
        'kopi_kafe' => OtwIcon.coffee,
        'oleh_oleh' => OtwIcon.gift,
        'religi' => OtwIcon.station,
        _ => OtwIcon.pin,
      };

  static Color tint(AppColors c, String code) => switch (code) {
        'alam' => c.accent,
        'budaya' || 'sejarah_budaya' || 'seni_kreatif' || 'religi' => c.info,
        'belanja' || 'kopi_kafe' => c.earth,
        'keluarga' => c.ink,
        _ => c.brand,
      };

  /// Latar lembut untuk kartu ide trip.
  static Color softBackground(AppColors c, String code) => switch (code) {
        'alam' => c.accentTint,
        'budaya' || 'sejarah_budaya' => c.sunTint,
        'belanja' => c.sunTint,
        _ => c.brandTint,
      };
}
