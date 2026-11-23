import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_icon.dart';
import '../../data/address_search.dart';

/// Daftar hasil cari lokasi di bawah kolom cari halaman tambah tujuan.
class AddressResultsPanel extends StatelessWidget {
  const AddressResultsPanel({
    required this.results,
    required this.loading,
    required this.error,
    required this.searched,
    required this.onPick,
    super.key,
  });

  final List<AddressResult> results;
  final bool loading;
  final bool error;

  /// True setelah pencarian online selesai (untuk pesan "tidak ketemu").
  final bool searched;
  final ValueChanged<AddressResult> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Material(
      color: c.surface200,
      elevation: 6,
      shadowColor: c.ink.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          children: [
            for (final r in results)
              ListTile(
                leading: OtwIconView(r.fromCatalog ? OtwIcon.star : OtwIcon.pin, size: 22, color: c.brand),
                title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(r.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => onPick(r),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
              )
            else if (error)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Text(AppCopy.searchFailed, style: text.bodySmall?.copyWith(color: c.inkMuted)),
              )
            else if (searched && results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Text(AppCopy.searchNotFound, style: text.bodySmall?.copyWith(color: c.inkMuted)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s1, AppSpacing.s4, AppSpacing.s2),
              child: Text(AppCopy.searchAttribution, style: text.labelSmall?.copyWith(color: c.inkMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
