import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/features/auth/presentation/login_screen.dart';
import 'package:aura_style/features/auth/presentation/sign_up_screen.dart';
import 'package:aura_style/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:aura_style/features/home/presentation/home_screen.dart';
import 'package:aura_style/features/wardrobe/presentation/wardrobe_screen.dart';
import 'package:aura_style/features/wardrobe/presentation/add_item_screen.dart';
import 'package:aura_style/features/tryon/presentation/virtual_tryon_canvas.dart';
import 'package:aura_style/features/profile/presentation/profile_screen.dart';
import 'package:aura_style/features/quiz/presentation/style_quiz_screen.dart';
import 'package:aura_style/features/splash/splash_screen.dart';

/// Helper class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;

      // Check if user is on login/signup pages
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/';

      // If not logged in and not on auth page, redirect to login
      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      // If logged in and on auth page, check onboarding status
      if (isLoggedIn && isOnAuthPage) {
        try {
          final profile = await supabase
              .from('user_profiles')
              .select('onboarding_completed')
              .eq('id', session.user.id)
              .single();

          final onboardingCompleted =
              profile['onboarding_completed'] as bool? ?? false;

          if (!onboardingCompleted) {
            return '/onboarding';
          } else {
            return '/home';
          }
        } catch (e) {
          // Profile not found, go to onboarding
          return '/onboarding';
        }
      }

      // Check if logged in but trying to access onboarding when already completed
      if (isLoggedIn && state.matchedLocation == '/onboarding') {
        try {
          final profile = await supabase
              .from('user_profiles')
              .select('onboarding_completed')
              .eq('id', session.user.id)
              .single();

          final onboardingCompleted =
              profile['onboarding_completed'] as bool? ?? false;

          if (onboardingCompleted) {
            return '/home';
          }
        } catch (e) {
          // Continue to onboarding if error
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/wardrobe',
        builder: (context, state) => const WardrobeScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddItemScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tryon',
        builder: (context, state) => const VirtualTryonCanvas(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const StyleQuizScreen(),
      ),
    ],
  );
}
