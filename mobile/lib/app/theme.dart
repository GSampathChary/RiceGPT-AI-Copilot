import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2F8F3A),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF2F8F3A),
    secondary: const Color(0xFF7A3FFC),
    tertiary: const Color(0xFFB14DFF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    textTheme: GoogleFonts.manropeTextTheme(),
    scaffoldBackgroundColor: const Color(0xFFF4F7F1),
    appBarTheme: AppBarTheme(
      backgroundColor: base.surface,
      foregroundColor: base.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDDF3E0),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5FC86A),
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF5FC86A),
    secondary: const Color(0xFFB07CFF),
    tertiary: const Color(0xFF7A3FFC),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: const Color(0xFF0B100D),
    appBarTheme: AppBarTheme(
      backgroundColor: base.surface,
      foregroundColor: base.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF162119),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF101713),
      indicatorColor: const Color(0xFF244A28),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
