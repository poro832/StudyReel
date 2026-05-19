import 'package:go_router/go_router.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/feed/feed_screen.dart';
import '../presentation/explore/explore_screen.dart';
import '../presentation/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, _) => const OnboardingScreen()),
    GoRoute(path: '/feed',       builder: (context, _) => const FeedScreen()),
    GoRoute(path: '/explore',    builder: (context, _) => const ExploreScreen()),
    GoRoute(path: '/profile',    builder: (context, _) => const ProfileScreen()),
  ],
);
