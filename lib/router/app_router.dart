import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lives_list/lives_list_screen.dart';
import '../features/viewer/viewer_panel_screen.dart';
import '../features/broadcaster/create_room_screen.dart';
import '../features/broadcaster/broadcaster_dashboard_screen.dart';
import '../features/auth/signin_screen.dart';
import '../features/auth/signup_screen.dart';
import '../data/models/live_room.dart';

final appRouter = GoRouter(
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
  redirect: (context, state) {
    // Keep old links working: /auth -> /auth/signin
    if (state.uri.toString() == '/auth') return '/auth/signin';
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route error: ${state.error}')),
  ),
);
