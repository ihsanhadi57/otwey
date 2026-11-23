import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/clock.dart';
import 'otw_time_picker_sheet.dart';
import 'otw_press.dart';

/// Rentang jam di luar rumah dalam menit sejak tengah malam.
typedef OtwTimeRange = ({int start, int end});

/// Bottom sheet satu layar untuk jam berangkat dan jam sampai rumah:
/// dua roda berdampingan, pintasan, dan ringkasan lama di luar rumah.
class OtwTimeRangeSheet extends StatefulWidget {
  const OtwTimeRangeSheet({required this.start, required this.end, super.key});

  final int start;
  final int end;

  @override
  State<OtwTimeRangeSheet> createState() => _OtwTimeRangeSheetState();
}

class _OtwTimeRangeSheetState extends State<OtwTimeRangeSheet> {
  static const _minGap = 120;
  static const _presets = <(String, int, int)>[
    (AppCopy.presetFullDay, 6 * 60, 21 * 60),
    (AppCopy.presetRelaxed, 8 * 60, 19 * 60),
    (AppCopy.presetShort, 9 * 60, 17 * 60),
  ];

  late int _start = widget.start ~/ 5 * 5;
  late int _end = widget.end ~/ 5 * 5;

  bool get _valid => _end - _start >= _minGap;

  void _preset(int s, int e) => setState(() {
        _start = s;
        _end = e;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
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
            Text(AppCopy.hoursOut, style: text.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                for (var i = 0; i < _presets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _PresetChip(
                      name: _presets[i].$1,
                      range: '${Clock.format(_presets[i].$2)}–${Clock.format(_presets[i].$3)}',
                      selected: _start == _presets[i].$2 && _end == _presets[i].$3,
                      onTap: () => _preset(_presets[i].$2, _presets[i].$3),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: _TimeColumn(
                    label: AppCopy.leaveLabel,
                    minutes: _start,
                    onChanged: (v) => setState(() => _start = v),
                  ),
                ),
                Container(width: 1, height: 200, color: c.line),
                Expanded(
                  child: _TimeColumn(
                    label: AppCopy.backHomeLabel,
                    minutes: _end,
                    onChanged: (v) => setState(() => _end = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              _valid ? AppCopy.hoursOutSummary(Clock.duration(_end - _start)) : AppCopy.hoursOutTooShort,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: _valid ? c.inkMuted : c.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: OtwOutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppCopy.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: OtwFilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _valid ? () => Navigator.of(context).pop((start: _start, end: _end)) : null,
                    child: Text(AppCopy.saveRange(Clock.format(_start), Clock.format(_end))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pintasan jam: tiga kotak sama lebar, nama di atas dan rentang jam di bawah.
class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.name, required this.range, required this.selected, required this.onTap});

  final String name;
  final String range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.brand : c.surface300,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: OtwInkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: text.labelLarge?.copyWith(
                        color: selected ? c.onBrand : c.ink, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(range,
                    style: AppTypography.timeSm(color: selected ? c.onBrand : c.inkMuted)
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatefulWidget {
  const _TimeColumn({required this.label, required this.minutes, required this.onChanged});

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeColumn> createState() => _TimeColumnState();
}

class _TimeColumnState extends State<_TimeColumn> {
  late int _hour = widget.minutes ~/ 60;
  late int _minute = widget.minutes % 60 ~/ 5 * 5;
  late final _h = FixedExtentScrollController(initialItem: _hour);
  late final _m = FixedExtentScrollController(initialItem: _minute ~/ 5);
  bool _animating = false;

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TimeColumn old) {
    super.didUpdateWidget(old);
    // Pintasan mengubah nilai dari luar: geser roda ke sana tanpa bangun ulang.
    if (widget.minutes != _hour * 60 + _minute) {
      _hour = widget.minutes ~/ 60;
      _minute = widget.minutes % 60 ~/ 5 * 5;
      const d = Duration(milliseconds: 250);
      _animating = true;
      Future.wait([
        _h.animateToItem(_hour, duration: d, curve: Curves.easeOut),
        _m.animateToItem(_minute ~/ 5, duration: d, curve: Curves.easeOut),
      ]).whenComplete(() => _animating = false);
    }
  }

  void _emit() {
    if (!_animating) widget.onChanged(_hour * 60 + _minute);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.brandStrong, fontWeight: FontWeight.w700)),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: c.surface300, borderRadius: BorderRadius.circular(12)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OtwTimeWheel(
                    width: 60,
                    controller: _h,
                    count: 24,
                    label: (i) => i.toString().padLeft(2, '0'),
                    onChanged: (i) {
                      _hour = i;
                      _emit();
                    },
                  ),
                  Text('.', style: AppTypography.time()),
                  OtwTimeWheel(
                    width: 60,
                    controller: _m,
                    count: 12,
                    label: (i) => (i * 5).toString().padLeft(2, '0'),
                    onChanged: (i) {
                      _minute = i * 5;
                      _emit();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Buka [OtwTimeRangeSheet]. Null kalau batal.
Future<OtwTimeRange?> showOtwTimeRange(
  BuildContext context, {
  required int start,
  required int end,
}) =>
    showModalBottomSheet<OtwTimeRange>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OtwTimeRangeSheet(start: start, end: end),
    );
