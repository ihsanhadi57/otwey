import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/itinerary.dart';
import 'status_banner.dart';

/// Banner status rencana, tujuan yang dilepas planner, dan tempat yang
/// dilepas setelah edit.
class ResultStatusBanners extends StatelessWidget {
  const ResultStatusBanners({required this.itinerary, this.showEditedDrops = false, super.key});

  final Itinerary itinerary;
  final bool showEditedDrops;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itinerary.status == PlanStatus.tight)
          StatusBanner(message: AppCopy.statusTight(Clock.duration(itinerary.spareMinutes)), warning: true)
        else if (itinerary.returnBuffer != null)
          StatusBanner(message: AppCopy.safeBuffer(Clock.duration(itinerary.returnBuffer!))),
        if (itinerary.droppedPinNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          StatusBanner(message: AppCopy.pinsDropped(itinerary.droppedPinNames), warning: true),
        ],
        if (showEditedDrops && itinerary.droppedPlaceNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          StatusBanner(message: AppCopy.droppedAfterEdit(itinerary.droppedPlaceNames.join(', ')), warning: true),
        ],
      ],
    );
  }
}
