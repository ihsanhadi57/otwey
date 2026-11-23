import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/transit_route_repository.dart';
import '../../domain/itinerary.dart';
import '../../domain/leg_mode.dart';
import 'leg_card.dart';

/// [LegCard] yang ikut menampilkan rute transum langsung dari Google bila
/// tersedia. Saat memuat, gagal, atau Supabase belum aktif, kartu tampil
/// seperti biasa.
class LiveLegCard extends ConsumerWidget {
  const LiveLegCard({
    required this.date,
    required this.leg,
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final DateTime date;
  final LegEntry leg;
  final LegMode mode;
  final ValueChanged<LegMode> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = leg.hasPoints && ref.watch(transitRouteRepositoryProvider) != null;
    final live = enabled
        ? ref
            .watch(liveTransitProvider(TransitQuery(
              fromLat: leg.fromLat!,
              fromLng: leg.fromLng!,
              toLat: leg.toLat!,
              toLng: leg.toLng!,
              date: date,
              departMinutes: leg.start,
            )))
            .value
        : null;
    return LegCard(leg: leg, mode: mode, onChanged: onChanged, live: live);
  }
}
