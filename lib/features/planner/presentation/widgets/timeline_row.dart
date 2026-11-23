import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Kerangka satu baris timeline: kolom jam, rel (penanda + garis putus), dan isi.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    required this.child,
    this.time,
    this.marker,
    this.markerTop = 0,
    this.timeTop = 3,
    this.showLine = true,
    this.emphasizeTime = false,
    this.lineDone = false,
    super.key,
  });

  /// Jam ditonjolkan (tebal, warna aksen), misalnya jam tiba.
  final bool emphasizeTime;

  /// Garis rel sudah dilewati (mode jalan): digambar penuh berwarna.
  final bool lineDone;

  final String? time;
  final Widget? marker;
  final double markerTop;
  final double timeTop;
  final bool showLine;
  final Widget child;

  static const markerSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const timeWidth = 44.0;
    const gap = 10.0;
    final lineTop = marker == null ? 0.0 : markerTop + markerSize + 2;
    return Stack(
      children: [
        if (showLine)
          Positioned(
            left: timeWidth + gap,
            width: markerSize,
            top: lineTop,
            bottom: 2,
            child: CustomPaint(painter: lineDone ? _SolidLine(color: c.brand) : _DashedLine(color: c.lineStrong.withValues(alpha: 0.45))),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeWidth,
              child: Padding(
                padding: EdgeInsets.only(top: timeTop),
                child: Text(
                  time ?? '',
                  textAlign: TextAlign.right,
                  style: AppTypography.timeSm(color: emphasizeTime ? c.accent : c.ink).copyWith(
                    fontSize: emphasizeTime ? 14 : 13,
                    fontWeight: emphasizeTime ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: markerSize,
              child: marker == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(top: markerTop),
                      child: SizedBox(height: markerSize, child: Center(child: marker)),
                    ),
            ),
            const SizedBox(width: gap),
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: child)),
          ],
        ),
      ],
    );
  }
}

class _DashedLine extends CustomPainter {
  _DashedLine({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + 4).clamp(0, size.height)), paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLine old) => old.color != color;
}

class _SolidLine extends CustomPainter {
  _SolidLine({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SolidLine old) => old.color != color;
}
