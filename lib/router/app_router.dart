import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/router_refresh.dart'; // add this


import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lives_list/lives_list_screen.dart';
import '../features/viewer/viewer_panel_screen.dart';
import '../features/broadcaster/create_room_screen.dart';
import '../features/broadcaster/broadcaster_dashboard_screen.dart';
import '../features/auth/signin_screen.dart';
import '../features/auth/signup_screen.dart';
import '../data/models/live_room.dart';

bool _isAuthRoute(String path) =>
    path.startsWith('/auth') || path == '/auth' || path == '/auth/';

final appRouter = GoRouter(
  // Show splash first; redirect below will move to sign-in or home automatically
  initialLocation: '/splash',

  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/auth/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lives',
      builder: (context, state) => const LivesListScreen(),
    ),
    GoRoute(
      path: '/lives/:id',
      builder: (context, state) {
        final room = state.extra as LiveRoom?;
        return ViewerPanelScreen(room: room);
      },
    ),
    GoRoute(
      path: '/broadcast/create',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/broadcast/dashboard',
      builder: (context, state) {
        final room = state.extra as LiveRoom?;
        return BroadcasterDashboardScreen(room: room);
      },
    ),
  ],

  // 🔐 Auth-aware redirects
  redirect: (context, state) {
    // Keep old links working
    if (state.uri.toString() == '/auth') return '/auth/signin';

    final session = Supabase.instance.client.auth.currentSession;
    final loggingIn = _isAuthRoute(state.matchedLocation);
    final atSplash = state.matchedLocation == '/splash';

    // Not logged in → only allow auth routes (or splash which will bounce to signin)
    if (session == null) {
      if (loggingIn) return null;
      if (atSplash) return '/auth/signin';
      return '/auth/signin';
    }

    // Logged in → block auth routes, send to home (or keep their target)
    if (session != null && loggingIn) {
      return '/home';
    }

    // Example protection: require auth for broadcaster routes
    if (session == null &&
        (state.matchedLocation.startsWith('/broadcast'))) {
      return '/auth/signin';
    }

    return null;
  },

  // 🔄 Re-run redirects automatically on login/logout/refresh
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route error: ${state.error}')),
  ),
);
