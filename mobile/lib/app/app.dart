import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state/app_state.dart';
import '../features/splash/splash_screen.dart';
import 'theme.dart';

class RiceGptApp extends StatelessWidget {
  const RiceGptApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RiceGPT AI',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: state.themeMode,
      home: const SplashScreen(),
    );
  }
}

