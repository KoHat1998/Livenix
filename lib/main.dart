import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart'; // moved file

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'router/app_router.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const LivenixApp());
}


class LivenixApp extends StatelessWidget {
  const LivenixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.darkThemeData(
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Livenix',
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
