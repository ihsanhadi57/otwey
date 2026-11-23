import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/itinerary.dart';
import '../../domain/leg_mode.dart';
import 'free_time_card.dart';
import 'live_leg_card.dart';
import 'locked_card.dart';
import 'point_content.dart';
import 'stop_card.dart';
import 'stop_number_badge.dart';
import 'timeline_row.dart';

/// Timeline lengkap itinerary dari berangkat sampai pulang.
class TimelineView extends StatelessWidget {
  const TimelineView({
    required this.itinerary,
    required this.choices,
    required this.onChoose,
    required this.onOpenStop,
    this.onRemoveStop,
    this.onFillMore,
    this.onReturnEarlier,
    this.doneSteps,
    super.key,
  });

  final ValueChanged<StopEntry>? onRemoveStop;
  final VoidCallback? onFillMore;
  final VoidCallback? onReturnEarlier;

  /// Mode jalan: jumlah langkah yang sudah lewat. Garis di kiri terisi sampai langkah aktif.
  final int? doneSteps;

  final Itinerary itinerary;
  final Map<String, LegMode> choices;
  final void Function(String legId, LegMode mode) onChoose;
  final ValueChanged<StopEntry> onOpenStop;

  @override
  Widget build(BuildContext context) {
    final entries = itinerary.entries;
    // Perpindahan (leg/jalan kaki) menempel ke langkah sesudahnya, jadi
    // indeks langkah hanya naik di entri yang bukan perpindahan.
    var step = 0;
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final isMove = e is LegEntry || e is WalkEntry;
      final done = doneSteps != null && (isMove ? step < doneSteps! : step + 1 <= doneSteps!);
      rows.add(_row(context, e, isLast: i == entries.length - 1, lineDone: done));
      if (!isMove) step++;
    }
    return Column(children: rows);
  }

  Widget _row(BuildContext context, TimelineEntry e, {required bool isLast, required bool lineDone}) {
    final c = context.colors;
    Widget icon(OtwIcon i, {Color? color, bool fill = false}) => OtwIconView(
          i,
          size: 24,
          color: color ?? c.ink,
          variant: fill ? OtwIconVariant.fill : OtwIconVariant.line,
          knock: c.surface100,
        );

    return switch (e) {
      final PointEntry p => TimelineRow(
          time: Clock.format(p.time),
          showLine: !isLast,
          lineDone: lineDone,
          emphasizeTime: p.kind == PointKind.arrive || p.kind == PointKind.arrivedHome,
          marker: switch (p.kind) {
            PointKind.start => icon(OtwIcon.home),
            PointKind.station => icon(OtwIcon.station),
            PointKind.arrive => icon(OtwIcon.station, color: c.accent, fill: true),
            PointKind.arrivedHome => icon(OtwIcon.home, color: c.accent, fill: true),
          },
          child: PointContent(
            title: p.title,
            subtitle: p.kind == PointKind.arrivedHome
                ? AppCopy.spareBefore(Clock.duration(itinerary.spareMinutes), Clock.format(itinerary.latestReturn))
                : p.subtitle,
            subtitleColor: p.kind == PointKind.arrivedHome ? c.accent : null,
            titleColor: p.kind == PointKind.arrive ? c.accent : null,
          ),
        ),
      final TrainEntry t => TimelineRow(
          lineDone: lineDone,
          time: Clock.format(t.departure),
          marker: icon(t.isFeeder ? OtwIcon.train : OtwIcon.whoosh, color: t.isFeeder ? c.modeFeeder : c.lineStrong),
          child: PointContent(
            title: t.isFeeder ? AppCopy.feederTitle(t.from, t.to) : AppCopy.trainTitle(t.from, t.to),
            subtitle: t.bufferMinutes == null
                ? AppCopy.trainArrive(Clock.duration(t.arrival - t.departure), Clock.format(t.arrival))
                : AppCopy.trainBuffer(Clock.duration(t.arrival - t.departure), Clock.duration(t.bufferMinutes!)),
            emphasis: false,
          ),
        ),
      final LegEntry l => TimelineRow(
          lineDone: lineDone,
          child: LiveLegCard(
            date: itinerary.date,
            leg: l,
            mode: choices[l.id] ?? l.recommended,
            onChanged: (m) => onChoose(l.id, m),
          ),
        ),
      final WalkEntry w => TimelineRow(
          lineDone: lineDone,
          child: Row(
            children: [
              OtwIconView(OtwIcon.walk, size: 18, color: c.inkMuted),
              const SizedBox(width: 6),
              Text(AppCopy.walkMinutes(w.minutes),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
      final StopEntry st => TimelineRow(
          lineDone: lineDone,
          time: Clock.format(st.time),
          timeTop: 18,
          markerTop: 12,
          marker: StopNumberBadge(st.number),
          child: StopCard(
            stop: st,
            onTap: () => onOpenStop(st),
            onRemove: onRemoveStop == null ? null : () => onRemoveStop!(st),
          ),
        ),
      final FreeTimeEntry f => TimelineRow(
          lineDone: lineDone,
          time: Clock.format(f.time),
          timeTop: 14,
          markerTop: 10,
          marker: icon(OtwIcon.clock, color: c.inkMuted),
          child: FreeTimeCard(
            entry: f,
            earlierReturn: itinerary.earlierReturnDeparture,
            onFillMore: f.beforeReturn && itinerary.moreStopsAvailable ? onFillMore : null,
            onReturnEarlier: f.beforeReturn ? onReturnEarlier : null,
          ),
        ),
      final LockedEntry lk => TimelineRow(
          lineDone: lineDone,
          time: Clock.format(lk.start),
          timeTop: 14,
          markerTop: 10,
          marker: icon(OtwIcon.lock, fill: true),
          child: LockedCard(entry: lk),
        ),
    };
  }
}
