import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'router/app_router.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
