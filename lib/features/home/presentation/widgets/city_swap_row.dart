import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../../../core/widgets/otw_press.dart';

/// Kota asal dan tujuan dengan tombol tukar arah di tengah.
class CitySwapRow extends StatefulWidget {
  const CitySwapRow({required this.from, required this.to, required this.onSwap, super.key});

  final String from;
  final String to;
  final VoidCallback onSwap;

  @override
  State<CitySwapRow> createState() => _CitySwapRowState();
}

class _CitySwapRowState extends State<CitySwapRow> {
  int _play = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final city = text.titleLarge?.copyWith(fontSize: 24, height: 30 / 24);
    final label = text.bodySmall?.copyWith(color: c.inkMuted);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(AppCopy.from, style: label), Text(widget.from, style: city)],
          ),
        ),
        Tooltip(
          message: AppCopy.swapDirection,
          child: OtwOutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              side: BorderSide(color: c.line),
            ),
            onPressed: () {
              setState(() => _play++);
              widget.onSwap();
            },
            child: OtwIconView(OtwIcon.swap, size: 22, color: c.brand, play: _play, semanticLabel: AppCopy.swapDirection),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Text(AppCopy.to, style: label), Text(widget.to, style: city)],
          ),
        ),
      ],
    );
  }
}
