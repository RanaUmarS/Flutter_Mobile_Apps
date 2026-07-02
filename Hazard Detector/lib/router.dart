// lib/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/providers.dart';
import 'screens/alarm_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

// ── Splash guard ──────────────────────────────────────────────────────────────
// The router must NEVER redirect away from /splash on its own.
// SplashScreen owns its own navigation timing via context.go().
// This flag ensures the redirect logic is a no-op while on splash,
// regardless of whether alarmState.loaded is already true at startup.
// Without this, a warm-start (cached SharedPrefs) causes the router to
// redirect to /dashboard before the splash even renders — causing the
// "previous screen flashes first" bug.
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final onSplash = state.matchedLocation == '/splash';

      // Splash screen navigates itself — never redirect away from it here.
      if (onSplash) return null;

      final alarmState = ref.read(alarmServiceProvider);

      // Don't redirect until history has finished loading
      if (!alarmState.loaded) return null;

      final alarmActive = alarmState.hasActiveAlarm;
      final onAlarm = state.matchedLocation == '/alarm';

      if (alarmActive && !onAlarm) return '/alarm';
      if (!alarmActive && onAlarm) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/alarm',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AlarmScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(alarmServiceProvider, (prev, next) {
      if (prev?.hasActiveAlarm != next.hasActiveAlarm ||
          prev?.loaded != next.loaded) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}