import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../copy/app_copy.dart';
import '../theme/app_spacing.dart';
import 'otw_icon.dart';
import 'otw_press.dart';

/// Header halaman: tombol kembali tanpa latar, judul, aksi opsional di kanan.
class OtwHeader extends StatelessWidget implements PreferredSizeWidget {
  const OtwHeader({
    required this.title,
    this.brandTitle = false,
    this.actions = const [],
    this.onBack,
    super.key,
  });

  final String title;

  /// True = judul Fredoka besar (halaman utama tab), false = judul UI tengah.
  final bool brandTitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canPop = onBack != null || context.canPop();
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: Row(
            children: [
              if (canPop)
                OtwIconButton(
                  tooltip: AppCopy.back,
                  onPressed: onBack ?? () => context.pop(),
                  icon: const OtwIconView(OtwIcon.back, size: 24),
                )
              else
                const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: brandTitle ? text.titleLarge?.copyWith(fontSize: 24) : text.titleMedium,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
