import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lives_list/lives_list_screen.dart';
import '../features/viewer/viewer_panel_screen.dart';
import '../features/broadcaster/create_room_screen.dart';
import '../features/broadcaster/broadcaster_dashboard_screen.dart';
import '../data/models/live_room.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
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
    // Simple splash → home redirect after a moment; handled in SplashScreen.
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route error: ${state.error}')),
  ),
);
