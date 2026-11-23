import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/date_label.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Buka lembar pilih tanggal OTWEY. Hanya [first] sampai [last] yang bisa
/// dipilih. Mengembalikan tanggal (tanpa jam) atau null kalau ditutup.
Future<DateTime?> showOtwDatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface100,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => OtwDatePickerSheet(
      initial: initial,
      first: first,
      last: last,
      title: title ?? AppCopy.dateQuestion,
    ),
  );
}

/// Kalender bulanan bergaya OTWEY dengan pintasan Hari ini, Besok, Sabtu ini.
class OtwDatePickerSheet extends StatefulWidget {
  const OtwDatePickerSheet({
    required this.initial,
    required this.first,
    required this.last,
    required this.title,
    super.key,
  });

  final DateTime initial;
  final DateTime first;
  final DateTime last;
  final String title;

  @override
  State<OtwDatePickerSheet> createState() => _OtwDatePickerSheetState();
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class _OtwDatePickerSheetState extends State<OtwDatePickerSheet> {
  late DateTime _selected = _day(widget.initial);
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);

  DateTime get _first => _day(widget.first);
  DateTime get _last => _day(widget.last);

  bool _enabled(DateTime d) => !d.isBefore(_first) && !d.isAfter(_last);

  void _pick(DateTime d) {
    setState(() {
      _selected = d;
      _month = DateTime(d.year, d.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final today = _first;
    final tomorrow = today.add(const Duration(days: 1));
    final saturday = today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
    final canPrev = DateTime(_month.year, _month.month).isAfter(DateTime(_first.year, _first.month));
    final canNext = DateTime(_month.year, _month.month).isBefore(DateTime(_last.year, _last.month));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(widget.title, style: text.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final (label, d) in [
                  (AppCopy.today, today),
                  (AppCopy.tomorrow, tomorrow),
                  if (saturday != today && saturday != tomorrow) (AppCopy.thisSaturday, saturday),
                ])
                  if (_enabled(d))
                    ChoiceChip(
                      label: Text(label),
                      selected: _selected == d,
                      onSelected: (_) => _pick(d),
                      showCheckmark: false,
                      selectedColor: c.ink,
                      labelStyle: TextStyle(
                        color: _selected == d ? c.onBrand : c.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(color: _selected == d ? c.ink : c.line),
                      backgroundColor: c.surface200,
                      shape: const StadiumBorder(),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(child: Text('${_monthName(_month)} ${_month.year}', style: text.titleSmall)),
                _NavButton(
                  icon: OtwIcon.back,
                  tooltip: AppCopy.prevMonth,
                  onPressed: canPrev ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
                ),
                const SizedBox(width: AppSpacing.s2),
                _NavButton(
                  icon: OtwIcon.chevron,
                  tooltip: AppCopy.nextMonth,
                  onPressed: canNext ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            _MonthGrid(
              month: _month,
              selected: _selected,
              today: today,
              enabled: _enabled,
              onPick: _pick,
            ),
            const SizedBox(height: AppSpacing.s4),
            OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => Navigator.pop(context, _selected),
              child: Text(AppCopy.pickDate(DateLabel.long(_selected))),
            ),
          ],
        ),
      ),
    );
  }

  static const _monthsLong = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _monthName(DateTime m) => _monthsLong[m.month - 1];
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.tooltip, required this.onPressed});

  final OtwIcon icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: OtwIconView(icon, size: 18, color: onPressed == null ? c.line : c.ink),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onPick,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final bool Function(DateTime) enabled;
  final ValueChanged<DateTime> onPick;

  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: text.labelSmall?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Row(
            children: [
              for (final d in cells.sublist(r * 7, r * 7 + 7))
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: d == null
                        ? const SizedBox.shrink()
                        : _DayCell(
                            day: d,
                            selected: d == selected,
                            today: d == today,
                            enabled: enabled(d),
                            onTap: () => onPick(d),
                          ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final color = selected
        ? c.onBrand
        : enabled
            ? c.ink
            : c.inkMuted.withValues(alpha: 0.4);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Semantics(
        button: enabled,
        selected: selected,
        label: DateLabel.long(day),
        excludeSemantics: true,
        child: Material(
          color: selected ? c.ink : Colors.transparent,
          shape: CircleBorder(side: today && !selected ? BorderSide(color: c.brand, width: 1.5) : BorderSide.none),
          child: OtwInkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Center(
              child: Text(
                '${day.day}',
                style: text.bodyMedium?.copyWith(color: color, fontWeight: selected || today ? FontWeight.w800 : FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
