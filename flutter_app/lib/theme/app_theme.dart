import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const burgundy = Color(0xFF5B1B1B);
  static const burgundyDark = Color(0xFF2A0E0E);
  static const parchment = Color(0xFFE8D7B9);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFBFA047);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: burgundy,
        brightness: Brightness.dark,
      ).copyWith(
        primary: gold,
        secondary: goldSoft,
        surface: const Color(0xFF171112),
        surfaceContainerHighest: const Color(0xFF221718),
        outlineVariant: const Color(0xFF4A3A2D),
      ),
    );

    final display = GoogleFonts.cinzelTextTheme(base.textTheme);
    final body = GoogleFonts.interTextTheme(display);

    return base.copyWith(
      textTheme: body.copyWith(
        titleLarge: body.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: burgundyDark,
        foregroundColor: parchment,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: parchment,
          letterSpacing: 0.4,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0B0C),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF151011),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3A2C1F)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF171112),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF4A3A2D)),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: parchment,
        ),
        contentTextStyle: body.bodyMedium?.copyWith(color: const Color(0xFFD9C8A9)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF3A2C1F)),
      tabBarTheme: TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: const Color(0xFFB6A48A),
        indicatorColor: gold,
        dividerColor: const Color(0xFF3A2C1F),
        labelStyle: GoogleFonts.cinzel(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: burgundy,
          foregroundColor: parchment,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: GoogleFonts.cinzel(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF120D0E),
        labelStyle: const TextStyle(color: Color(0xFFB6A48A)),
        hintStyle: const TextStyle(color: Color(0xFF8F7F6A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A2C1F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A2C1F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: goldSoft,
        textColor: Color(0xFFE8D7B9),
      ),
    );
  }
}

