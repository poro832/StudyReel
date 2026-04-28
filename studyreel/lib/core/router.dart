import 'package:go_router/go_router.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/feed/feed_screen.dart';
import '../presentation/detail/card_detail_screen.dart';
import '../presentation/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, _) => const OnboardingScreen()),
    GoRoute(path: '/feed',       builder: (context, _) => const FeedScreen()),
    GoRoute(
      path: '/detail/:cardId',
      builder: (context, state) =>
          CardDetailScreen(cardId: state.pathParameters['cardId']!),
    ),
    GoRoute(path: '/profile',    builder: (context, _) => const ProfileScreen()),
  ],
);
