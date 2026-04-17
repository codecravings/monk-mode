import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/access_flow/countdown_screen.dart';
import '../presentation/screens/access_flow/pain_confirmation_screen.dart';
import '../presentation/screens/access_flow/regret_mirror_screen.dart';
import '../presentation/screens/access_flow/why_screen.dart';
import '../presentation/screens/app_drawer_screen.dart';
import '../presentation/screens/app_picker_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/dock_picker_screen.dart';
import '../presentation/screens/emergency_pass_screen.dart';
import '../presentation/screens/launcher_home_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/vault_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const LauncherHomeScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/app-drawer',
      builder: (_, __) => const AppDrawerScreen(),
    ),
    GoRoute(
      path: '/app-picker',
      builder: (_, __) => const AppPickerScreen(),
    ),
    GoRoute(
      path: '/dock-picker',
      builder: (_, __) => const DockPickerScreen(),
    ),
    GoRoute(
      path: '/vault',
      builder: (_, __) => const VaultScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/access-flow/why',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return WhyScreen(
          packageName: extra['packageName'] as String? ?? '',
          appName: extra['appName'] as String? ?? 'App',
        );
      },
    ),
    GoRoute(
      path: '/access-flow/regret',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return RegretMirrorScreen(
          packageName: extra['packageName'] as String? ?? '',
          appName: extra['appName'] as String? ?? 'App',
        );
      },
    ),
    GoRoute(
      path: '/access-flow/pain',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PainConfirmationScreen(
          packageName: extra['packageName'] as String? ?? '',
          appName: extra['appName'] as String? ?? 'App',
        );
      },
    ),
    GoRoute(
      path: '/access-flow/countdown',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CountdownScreen(
          packageName: extra['packageName'] as String? ?? '',
          appName: extra['appName'] as String? ?? 'App',
        );
      },
    ),
    GoRoute(
      path: '/emergency-pass',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return EmergencyPassScreen(
          packageName: extra['packageName'] as String? ?? '',
          appName: extra['appName'] as String? ?? 'App',
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF080808),
    body: Center(
      child: Text(
        'Route not found: ${state.uri}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
