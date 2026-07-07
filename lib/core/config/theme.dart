import 'package:flutter/material.dart';

class AppTheme {
  // Theme colors
  static const Color background = Color(0xFF000000); // 100% black
  static const Color darkGray = Color(0xFF1E1E1E); // Fog of war / Explored
  static const Color accentNeon = Color(0xFF00FFCC); // Neon green-cyan (Flashlight / Sonar)
  static const Color accentBlue = Color(0xFF00E5FF); // Deep blue neon
  static const Color accentPurple = Color(0xFFBD00FF); // Purple neon (Security / Obstacles)
  static const Color accentRed = Color(0xFFFF0055); // Red warning neon (Enemies / Lasers)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);

  // Flashlight properties
  static const Color flashlightCenter = Color(0xAAFFFFFF);
  static const Color flashlightEdge = Color(0x00000000);

  // Gradient definitions
  static const LinearGradient neonGreenBlue = LinearGradient(
    colors: [accentNeon, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [accentPurple, accentRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: accentNeon,
        secondary: accentBlue,
        error: accentRed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: accentNeon,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: accentNeon,
              blurRadius: 10,
            ),
          ],
        ),
        titleMedium: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 18,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 14,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 12,
          color: textSecondary,
        ),
      ),
    );
  }
}
