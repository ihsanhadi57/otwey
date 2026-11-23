import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/itinerary.dart';

/// Satu langkah transum: ikon moda, badge koridor (kalau ada), keterangan.
class TransitStepRow extends StatelessWidget {
  const TransitStepRow({required this.step, super.key});

  final TransitStep step;

  static OtwIcon iconOf(TransitKind k) => switch (k) {
        TransitKind.walk => OtwIcon.walk,
        TransitKind.rail => OtwIcon.train,
        TransitKind.bus => OtwIcon.bus,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final (fg, bg) = switch (step.tone) {
      CorridorTone.rail => (c.info, c.infoTint),
      CorridorTone.brt => (c.accent, c.accentTint),
      CorridorTone.city => (c.brandStrong, c.brandTint),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtwIconView(iconOf(step.kind), size: 20, color: c.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (step.corridor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(step.corridor!, style: text.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                ),
              Text(step.text, style: text.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
