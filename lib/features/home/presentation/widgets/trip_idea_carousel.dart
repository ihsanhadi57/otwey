import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/copy/app_copy.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/otw_section_title.dart';
import '../../../trip_setup/presentation/trip_draft_notifier.dart';
import 'trip_idea_card.dart';

/// Ide trip sehari. Tap = isi vibes di rencana lalu buka Atur rencana.
///
/// TODO(hadi): ambil ide dari data kurasi (misalnya tabel `mst_trip_idea`).
class TripIdeaCarousel extends ConsumerWidget {
  const TripIdeaCarousel({super.key});

  static const _ideas = [
    ('jajanan', 'kulineran', 'Kulineran Braga', 'Bandung · ± 6 j · Hemat'),
    ('alam', 'alam', 'Healing Lembang', 'Bandung · ± 7 j · Sedang'),
    ('budaya', 'budaya', 'Kota Tua Jakarta', 'Jakarta · ± 5 j · Hemat'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: OtwSectionTitle(AppCopy.tripIdeas),
        ),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: _ideas.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
            itemBuilder: (context, i) {
              final (iconCode, vibe, title, meta) = _ideas[i];
              return TripIdeaCard(
                vibeCode: iconCode,
                title: title,
                meta: meta,
                onTap: () {
                  ref.read(tripDraftProvider.notifier).setTripType(vibe);
                  context.push(AppRoutes.plan);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
