import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Baris ya/tidak dengan switch. Dipakai di form dan pengaturan.
class OtwSwitchRow extends StatelessWidget {
  const OtwSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.boxed = true,
    super.key,
  });

  final OtwIcon icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// True = kartu sendiri dengan garis. False = baris di dalam grup.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final row = MergeSemantics(
      child: OtwInkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 10),
          child: Row(
            children: [
              OtwIconView(icon, size: 24, color: c.ink),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    if (description != null)
                      Text(description!, style: text.bodySmall?.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: c.accent,
              ),
            ],
          ),
        ),
      ),
    );
    if (!boxed) return row;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface200,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: c.line),
      ),
      child: row,
    );
  }
}
