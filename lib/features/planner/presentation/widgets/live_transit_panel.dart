import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';
import '../../domain/transit_route.dart';
import 'live_transit_steps.dart';

/// Opsi transum dari Google di bawah kartu perpindahan, bisa dibuka-tutup.
///
/// Hanya informasi: jadwal rencana tetap dari planner. Kalau rute transum
/// lebih lama dari waktu yang dijadwalkan, user diberi tahu dengan jujur.
class LiveTransitPanel extends StatefulWidget {
  const LiveTransitPanel({required this.route, required this.start, required this.plannedMinutes, super.key});

  final TransitRoute route;

  /// Jam mulai perpindahan (menit sejak tengah malam).
  final int start;

  /// Menit perpindahan menurut rencana (moda yang sedang dipilih).
  final int plannedMinutes;

  @override
  State<LiveTransitPanel> createState() => _LiveTransitPanelState();
}

class _LiveTransitPanelState extends State<LiveTransitPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final r = widget.route;
    final extra = r.minutes - widget.plannedMinutes;
    final firstRide = r.rides.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s2),
        const Divider(),
        OtwInkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                OtwIconView(firstRide.mode == TransitMode.bus ? OtwIcon.bus : OtwIcon.train, size: 20, color: c.info),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppCopy.liveTransitTitle, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        AppCopy.liveTransitSummary(Clock.duration(r.minutes), Clock.format(widget.start + r.minutes)),
                        style: text.bodySmall?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: OtwIconView(OtwIcon.chevron, size: 18, color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (extra > 5) ...[
                      Text(
                        AppCopy.liveTransitSlower(Clock.duration(extra)),
                        style: text.bodySmall?.copyWith(color: c.warning, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                    ],
                    LiveTransitSteps(route: r),
                  ],
                ),
        ),
      ],
    );
  }
}
