import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/splash/splash_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/onboarding/topic_edit_screen.dart';
import '../presentation/feed/feed_screen.dart';
import '../presentation/explore/explore_screen.dart';
import '../presentation/profile/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshListenable =
      GoRouterRefreshStream(authRepository.authStateChanges);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isSignedIn = authRepository.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // 인증만 게이팅한다. 토픽 유무에 따른 온보딩/피드 분기는 스플래시('/')가 처리.
      if (!isSignedIn) {
        return isLoginRoute ? null : '/login';
      }
      if (isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/topics',
        builder: (context, _) => const TopicEditScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, _) => const FeedScreen()),
      GoRoute(path: '/explore', builder: (context, _) => const ExploreScreen()),
      GoRoute(path: '/profile', builder: (context, _) => const ProfileScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
