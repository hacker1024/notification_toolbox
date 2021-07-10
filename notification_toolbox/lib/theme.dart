import 'package:flutter/material.dart';

ThemeData buildTheme() => ThemeData(
      primaryColor: const Color(0xFF303B1A),
      colorScheme: const ColorScheme(
        primary: Color(0xFF303B1A),
        primaryVariant: Color(0xFF172004),
        secondary: Color(0xFF807D10),
        secondaryVariant: Color(0xFF57550C),
        surface: Colors.white,
        background: Colors.white,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );

ThemeData buildDarkTheme() {
  final lightTheme = buildTheme();
  return ThemeData(
    primaryColor: const Color(0xFF858219),
    colorScheme: lightTheme.colorScheme.copyWith(
      primary: const Color(0xFFC9C527),
      primaryVariant: const Color(0xFF989521),
      surface: const Color(0xFF121212),
      background: const Color(0xFF121212),
      error: const Color(0xFFCF6679),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
      brightness: Brightness.dark,
    ),
    pageTransitionsTheme: lightTheme.pageTransitionsTheme,
  );
}
