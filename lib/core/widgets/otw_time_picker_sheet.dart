import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/clock.dart';
import 'otw_press.dart';

/// Bottom sheet roda jam dan menit (menit per 5). Tidak pernah memunculkan keyboard.
class OtwTimePickerSheet extends StatefulWidget {
  const OtwTimePickerSheet({
    required this.title,
    required this.initialMinutes,
    this.contextLabel,
    super.key,
  });

  final String title;

  /// Menit sejak tengah malam.
  final int initialMinutes;

  /// Info kecil di kanan judul, misalnya "Selesai 15.00".
  final String? contextLabel;

  @override
  State<OtwTimePickerSheet> createState() => _OtwTimePickerSheetState();
}

class _OtwTimePickerSheetState extends State<OtwTimePickerSheet> {
  late int _hour = widget.initialMinutes ~/ 60;
  late int _minute = (widget.initialMinutes % 60) ~/ 5 * 5;
  late final _hourCtrl = FixedExtentScrollController(initialItem: _hour);
  late final _minuteCtrl = FixedExtentScrollController(initialItem: _minute ~/ 5);

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final value = _hour * 60 + _minute;
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
            Row(
              children: [
                Expanded(child: Text(widget.title, style: text.titleMedium)),
                if (widget.contextLabel != null)
                  Text(widget.contextLabel!, style: text.bodySmall?.copyWith(color: c.inkMuted)),
              ],
            ),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(color: c.surface300, borderRadius: BorderRadius.circular(12)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OtwTimeWheel(
                        controller: _hourCtrl,
                        count: 24,
                        label: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _hour = i),
                      ),
                      Text('.', style: AppTypography.time()),
                      OtwTimeWheel(
                        controller: _minuteCtrl,
                        count: 12,
                        label: (i) => (i * 5).toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _minute = i * 5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              AppCopy.timePickerHint,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: c.inkMuted),
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
                    onPressed: () => Navigator.of(context).pop(value),
                    child: Text(AppCopy.saveTime(Clock.format(value))),
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

class OtwTimeWheel extends StatelessWidget {
  const OtwTimeWheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.onChanged,
    this.width = 96,
    super.key,
  });

  final double width;
  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => onChanged(i % count),
        childDelegate: ListWheelChildLoopingListDelegate(
          children: [
            for (var i = 0; i < count; i++)
              Center(child: Text(label(i), style: AppTypography.time())),
          ],
        ),
      ),
    );
  }
}

/// Buka [OtwTimePickerSheet]. Hasil menit sejak tengah malam, null kalau batal.
Future<int?> showOtwTimePicker(
  BuildContext context, {
  required String title,
  required int initialMinutes,
  String? contextLabel,
}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OtwTimePickerSheet(
        title: title,
        initialMinutes: initialMinutes,
        contextLabel: contextLabel,
      ),
    );
