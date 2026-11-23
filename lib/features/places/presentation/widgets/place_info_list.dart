import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_badge.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place.dart';
import '../../domain/place_attribute.dart';
import 'place_info_row.dart';

/// Info praktis tempat dalam satu kartu: jam buka, harga, lama, cocok buat.
class PlaceInfoList extends StatelessWidget {
  const PlaceInfoList({required this.place, required this.now, super.key});

  final Place place;
  final DateTime now;

  static String _price(PriceRange? p) => switch (p) {
        PriceRange.murah => AppCopy.budgetHemat,
        PriceRange.sedang => AppCopy.budgetSedang,
        PriceRange.mahal => AppCopy.budgetSultan,
        null => '-',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = place.openingHours.where((h) => h.dayOfWeek == now.weekday).toList();
    final minuteNow = now.hour * 60 + now.minute;
    final openNow = today.any((h) => h.open <= minuteNow && minuteNow < h.close);
    final goodFor = PlaceAttribute.labelsOf(place.attributeCodes);
    final rows = <Widget>[
      PlaceInfoRow(
        icon: OtwIcon.clock,
        label: AppCopy.openToday,
        value: today.isEmpty
            ? AppCopy.closedNow
            : today.map((h) => '${Clock.format(h.open)} – ${Clock.format(h.close)}').join(', '),
        trailing: today.isEmpty
            ? null
            : OtwBadge(openNow ? AppCopy.openNow : AppCopy.closedNow,
                tone: openNow ? OtwBadgeTone.success : OtwBadgeTone.soft),
      ),
      PlaceInfoRow(icon: OtwIcon.wallet, label: AppCopy.priceRange, value: _price(place.priceRange)),
      PlaceInfoRow(icon: OtwIcon.walk, label: AppCopy.stayTime, value: Clock.duration(place.visitMinutes)),
      if (goodFor.isNotEmpty) PlaceInfoRow(icon: OtwIcon.star, label: AppCopy.goodFor, value: goodFor.join(' · ')),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface200,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 48),
            rows[i],
          ],
        ],
      ),
    );
  }
}
