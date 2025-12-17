import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/pairing_screen.dart';
import '../../features/auth/presentation/screens/permission_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/messages/presentation/screens/compose_message_screen.dart';
import '../../features/voice_notes/presentation/screens/voice_notes_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/gallery/presentation/screens/add_memory_screen.dart';
import '../../features/gallery/presentation/screens/slideshow_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Provider for the app router with authentication guard
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// App Router configuration using go_router
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Auth routes that don't require authentication
  static const _publicRoutes = [
    Routes.splashPath,
    Routes.onboardingPath,
    Routes.loginPath,
    Routes.signupPath,
  ];

  /// Create router with authentication guard
  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: Routes.splashPath,
      debugLogDiagnostics: true,

      // Authentication redirect guard
      redirect: (context, state) {
        // Use Firebase Auth directly to get current auth state (avoids stream timing issues)
        final firebaseUser = fb.FirebaseAuth.instance.currentUser;
        final isLoggedIn = firebaseUser != null;
        final currentPath = state.uri.path;
        final isPublicRoute = _publicRoutes.contains(currentPath);
        final isPairingRoute = currentPath == Routes.pairingPath;

        // If on splash screen, don't redirect (splash handles its own navigation)
        if (currentPath == Routes.splashPath) {
          return null;
        }

        // If not logged in and trying to access protected route, go to login
        if (!isLoggedIn && !isPublicRoute && !isPairingRoute) {
          return Routes.loginPath;
        }

        // If logged in and trying to access login/signup, redirect to home
        if (isLoggedIn && isPublicRoute && currentPath != Routes.splashPath) {
          return Routes.homePath;
        }

        return null; // No redirect needed
      },

      routes: [
        // ═══════════════════════════════════════════════════════════════════════
        // AUTH ROUTES (without bottom nav)
        // ═══════════════════════════════════════════════════════════════════════
        GoRoute(
          path: Routes.splashPath,
          name: Routes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.onboardingPath,
          name: Routes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: Routes.loginPath,
          name: Routes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: Routes.signupPath,
          name: Routes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: Routes.pairingPath,
          name: Routes.pairing,
          builder: (context, state) => const PairingScreen(),
        ),
        GoRoute(
          path: Routes.permissionSetupPath,
          name: Routes.permissionSetup,
          builder: (context, state) => const PermissionSetupScreen(),
        ),

        // ═══════════════════════════════════════════════════════════════════════
        // MAIN APP ROUTES (with persistent bottom navigation)
        // ═══════════════════════════════════════════════════════════════════════
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainScaffold(currentPath: state.uri.path, child: child);
          },
          routes: [
            // Home
            GoRoute(
              path: Routes.homePath,
              name: Routes.home,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: const HomeScreen()),
            ),

            // Messages routes
            GoRoute(
              path: Routes.messagesPath,
              name: Routes.messages,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: const MessagesScreen()),
            ),

            // Gallery routes
            GoRoute(
              path: Routes.galleryPath,
              name: Routes.gallery,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: const GalleryScreen()),
            ),

            // Events route
            GoRoute(
              path: Routes.eventsPath,
              name: Routes.events,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: const EventsScreen()),
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════════════
        // OVERLAY ROUTES (without bottom nav - modals/details)
        // ═══════════════════════════════════════════════════════════════════════
        GoRoute(
          path: Routes.composeMessagePath,
          name: Routes.composeMessage,
          builder: (context, state) => const ComposeMessageScreen(),
        ),
        GoRoute(
          path: Routes.voiceNotesPath,
          name: Routes.voiceNotes,
          builder: (context, state) => const VoiceNotesScreen(),
        ),
        GoRoute(
          path: Routes.addMemoryPath,
          name: Routes.addMemory,
          builder: (context, state) => const AddMemoryScreen(),
        ),
        GoRoute(
          path: Routes.slideshowPath,
          name: Routes.slideshow,
          builder: (context, state) {
            final startIndex = state.extra as int? ?? 0;
            return SlideshowScreen(startIndex: startIndex);
          },
        ),
        GoRoute(
          path: Routes.settingsPath,
          name: Routes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],

      // Error page
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.homePath),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
