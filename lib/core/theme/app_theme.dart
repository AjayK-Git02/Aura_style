import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - User Custom (Pastel & Fresh)
  static const Color primaryColor = Color(0xFF92C7CF);   // Soft Cyan/Blue
  static const Color primaryDark = Color(0xFF7AB0B8);    // Slightly darker version
  static const Color secondaryColor = Color(0xFFAAD7D9); // Light Blue
  static const Color accentColor = Color(0xFFE5E1DA);    // Light Beige/Tan
  
  // Backgrounds
  static const Color scaffoldBackgroundColor = Color(0xFFFBF9F1); // Cream/Off-White
  static const Color surfaceColor = Color(0xFFFFFFFF);            // White
  static const Color cardColor = Color(0xFFFFFFFF);               // White for cards
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E1E);    // Dark Grey for readability
  static const Color textSecondary = Color(0xFF757575);  // Medium Grey

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography Styles (Static for direct usage)
  static final TextStyle headlineLarge = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static final TextStyle headlineMedium = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle headlineSmall = GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle bodyLarge = GoogleFonts.lato(
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.lato(
    fontSize: 14,
    color: textSecondary,
    height: 1.5,
  );

  static final TextStyle labelLarge = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.0,
  );
  
  // Light Theme (Default)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: scaffoldBackgroundColor,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.black, // Dark text on light pastel primary
      onSecondary: Colors.black, // Dark text on light pastel secondary
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    
    // Typography
    textTheme: TextTheme(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: labelLarge.copyWith(color: Colors.black), // Ensure button label is black
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      hintStyle: GoogleFonts.lato(color: Colors.black38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black, // Black text for contrast
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: headlineSmall,
      contentTextStyle: bodyLarge,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.lato(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
