import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/fade_branch_container.dart';
import '../../features/account/presentation/account_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/live/presentation/live_trip_page.dart';
import '../../features/places/presentation/explore_page.dart';
import '../../features/places/presentation/place_detail_page.dart';
import '../../features/places/presentation/wishlist_page.dart';
import '../../features/planner/presentation/generating_page.dart';
import '../../features/planner/presentation/result_page.dart';
import '../../features/planner/presentation/stop_detail_page.dart';
import '../../features/saved_trips/presentation/saved_trips_page.dart';
import '../../features/shell/presentation/app_shell_page.dart';
import '../../features/trip_setup/presentation/add_pin_page.dart';
// import '../../features/trip_setup/presentation/onboarding_page.dart';
import '../../features/trip_setup/presentation/origin_map_page.dart';
import '../../features/trip_setup/presentation/origin_picker_page.dart';
import '../../features/trip_setup/presentation/plan_setup_page.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Onboarding sementara dilewati: buka aplikasi langsung ke Beranda.
    initialLocation: AppRoutes.home,
    routes: [
      // GoRoute(
      //   path: AppRoutes.onboarding,
      //   builder: (context, state) => const OnboardingPage(),
      // ),
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) => FadeBranchContainer(
          index: shell.currentIndex,
          children: children,
        ),
        builder: (context, state, shell) => AppShellPage(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.explore, builder: (context, state) => const ExplorePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.trips, builder: (context, state) => const SavedTripsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.account, builder: (context, state) => const AccountPage()),
          ]),
        ],
      ),
      GoRoute(path: AppRoutes.origin, builder: (context, state) => const OriginPickerPage()),
      GoRoute(path: AppRoutes.originMap, builder: (context, state) => const OriginMapPage()),
      GoRoute(path: AppRoutes.wishlist, builder: (context, state) => const WishlistPage()),
      GoRoute(path: AppRoutes.plan, builder: (context, state) => const PlanSetupPage()),
      GoRoute(path: AppRoutes.addPin, builder: (context, state) => const AddPinPage()),
      GoRoute(path: AppRoutes.generating, builder: (context, state) => const GeneratingPage()),
      GoRoute(path: AppRoutes.result, builder: (context, state) => const ResultPage()),
      GoRoute(path: AppRoutes.savedPlan, builder: (context, state) => const ResultPage(saved: true)),
      GoRoute(path: AppRoutes.live, builder: (context, state) => const LiveTripPage()),
      GoRoute(
        path: AppRoutes.stopPattern,
        builder: (context, state) => StopDetailPage(placeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.placePattern,
        builder: (context, state) => PlaceDetailPage(placeId: state.pathParameters['id']!),
      ),
    ],
  );
});
