import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_segmented.dart';
import '../../../../core/widgets/otw_switch_row.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../domain/place_attribute.dart';
import '../../domain/place_filter.dart';
import '../../../../core/widgets/otw_press.dart';

/// Lembar filter Jelajah. [countOf] menghitung hasil untuk filter yang sedang
/// diatur, supaya tombol bisa menampilkan jumlah tempat sebelum diterapkan.
Future<PlaceFilter?> showPlaceFilterSheet(
  BuildContext context, {
  required PlaceFilter initial,
  required int Function(PlaceFilter) countOf,
}) {
  return showModalBottomSheet<PlaceFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface100,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => _PlaceFilterSheet(initial: initial, countOf: countOf),
  );
}

class _PlaceFilterSheet extends StatefulWidget {
  const _PlaceFilterSheet({required this.initial, required this.countOf});

  final PlaceFilter initial;
  final int Function(PlaceFilter) countOf;

  @override
  State<_PlaceFilterSheet> createState() => _PlaceFilterSheetState();
}

class _PlaceFilterSheetState extends State<_PlaceFilterSheet> {
  late PlaceFilter _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final count = widget.countOf(_f);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(AppCopy.filterTitle, style: text.titleMedium)),
                OtwTextButton(
                  onPressed: _f.activeCount == 0 ? null : () => setState(() => _f = _f.cleared()),
                  child: const Text(AppCopy.filterReset),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            OtwSwitchRow(
              icon: OtwIcon.clock,
              label: AppCopy.filterOpenNow,
              value: _f.openNow,
              onChanged: (v) => setState(() => _f = _f.copyWith(openNow: v)),
            ),
            const SizedBox(height: AppSpacing.s2),
            OtwSwitchRow(
              icon: OtwIcon.heart,
              label: AppCopy.filterOnlySaved,
              value: _f.onlySaved,
              onChanged: (v) => setState(() => _f = _f.copyWith(onlySaved: v)),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(AppCopy.filterBudget, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.s2),
            OtwSegmented<String>(
              semanticLabel: AppCopy.filterBudget,
              selected: _f.maxBudget ?? '',
              onChanged: (v) => setState(() => _f = v.isEmpty ? _f.copyWith(clearBudget: true) : _f.copyWith(maxBudget: v)),
              segments: const [
                OtwSegment(value: '', label: AppCopy.filterAll),
                OtwSegment(value: 'murah', label: AppCopy.budgetHemat),
                OtwSegment(value: 'sedang', label: AppCopy.budgetSedang),
                OtwSegment(value: 'mahal', label: AppCopy.budgetSultan),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(AppCopy.filterFeatures, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final code in PlaceAttribute.filterable)
                  FilterChip(
                    label: Text(PlaceAttribute.label(code)),
                    selected: _f.attributes.contains(code),
                    showCheckmark: false,
                    selectedColor: c.ink,
                    backgroundColor: c.surface200,
                    side: BorderSide(color: _f.attributes.contains(code) ? c.ink : c.line),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      color: _f.attributes.contains(code) ? c.onBrand : c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (on) => setState(() {
                      final next = {..._f.attributes};
                      on ? next.add(code) : next.remove(code);
                      _f = _f.copyWith(attributes: next);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            OtwFilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => Navigator.pop(context, _f),
              child: Text(AppCopy.filterApply(count)),
            ),
          ],
        ),
      ),
    );
  }
}
