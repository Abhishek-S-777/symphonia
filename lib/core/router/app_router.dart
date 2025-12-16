import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/pairing_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/messages/presentation/screens/compose_message_screen.dart';
import '../../features/voice_notes/presentation/screens/voice_notes_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/gallery/presentation/screens/add_memory_screen.dart';
import '../../features/gallery/presentation/screens/slideshow_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// App Router configuration using go_router
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splashPath,
    debugLogDiagnostics: true,
    routes: [
      // ═══════════════════════════════════════════════════════════════════════
      // AUTH ROUTES
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

      // ═══════════════════════════════════════════════════════════════════════
      // MAIN APP ROUTES (with bottom navigation)
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: Routes.homePath,
        name: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // Messages routes
      GoRoute(
        path: Routes.messagesPath,
        name: Routes.messages,
        builder: (context, state) => const MessagesScreen(),
        routes: [
          GoRoute(
            path: 'compose',
            name: Routes.composeMessage,
            builder: (context, state) => const ComposeMessageScreen(),
          ),
        ],
      ),

      // Voice notes route
      GoRoute(
        path: Routes.voiceNotesPath,
        name: Routes.voiceNotes,
        builder: (context, state) => const VoiceNotesScreen(),
      ),

      // Gallery routes
      GoRoute(
        path: Routes.galleryPath,
        name: Routes.gallery,
        builder: (context, state) => const GalleryScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: Routes.addMemory,
            builder: (context, state) => const AddMemoryScreen(),
          ),
          GoRoute(
            path: 'slideshow',
            name: Routes.slideshow,
            builder: (context, state) {
              final startIndex = state.extra as int? ?? 0;
              return SlideshowScreen(startIndex: startIndex);
            },
          ),
        ],
      ),

      // Settings route
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
