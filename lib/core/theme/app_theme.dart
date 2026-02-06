import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ----------------------------
  // Core Brand Colors
  // ----------------------------
  static const Color primaryColor = Color(0xFF03045E); // Brand Navy
  static const Color secondaryColor = Color(0xFF0077B6); // Brand Blue
  static const Color accentColor = Color(0xFF2EC4B6); // Teal Accent
  static const Color successColor = Color(0xFF2EC4B6); // Success
  static const Color errorColor = Color(0xFFC1121F); // Error Red
  static const Color warningColor = Color(0xFFFCA311); // Warning Amber
  static const Color infoColor = Color(0xFF0077B6); // Info = Brand Blue

  // Surfaces & Backgrounds
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFEDFCFF); // Light Ice
  static const Color backgroundDark = Color(0xFF03045E); // Deep Navy

  // Text Colors
  static const Color textPrimary = Color(0xFF03045E);
  static const Color textSecondary = Color(0xFF4A6FA5);
  static const Color textDisabled = Color(0xFF9DB4C0);
  static const Color textWhite = Colors.white;
  static const Color textWhiteSecondary = Color(0x80FFFFFF); // 50% opacity

  // ----------------------------
  // Spacing
  // ----------------------------
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ----------------------------
  // Border Radius
  // ----------------------------
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;

  // ----------------------------
  // Font Sizes
  // ----------------------------
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;

  // ----------------------------
  // Font Weights
  // ----------------------------
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ----------------------------
  // Shadows
  // ----------------------------
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  // ----------------------------
  // Typography
  // ----------------------------
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: fontSize24,
        fontWeight: fontWeightBold,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: fontSize20,
        fontWeight: fontWeightBold,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: fontSize18,
        fontWeight: fontWeightBold,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: fontSize16,
        fontWeight: fontWeightSemiBold,
        color: textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: fontSize16,
        fontWeight: fontWeightNormal,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: fontSize14,
        fontWeight: fontWeightNormal,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: fontSize12,
        fontWeight: fontWeightNormal,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: fontSize14,
        fontWeight: fontWeightMedium,
        color: textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: fontSize12,
        fontWeight: fontWeightMedium,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: fontSize10,
        fontWeight: fontWeightMedium,
        color: textSecondary,
        height: 1.4,
        letterSpacing: 1.0,
      );

  // ----------------------------
  // Component Decorations
  // ----------------------------
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [shadowSm],
      );

  static BoxDecoration get cardDecorationDark => BoxDecoration(
        color: backgroundDark,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: const Color(0xFF374151)),
        boxShadow: const [shadowSm],
      );

  static BoxDecoration get successHeaderDecoration => BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius32),
          bottomRight: Radius.circular(radius32),
        ),
      );

  static BoxDecoration get mapPreviewDecoration => BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: surfaceColor, width: 4),
        boxShadow: const [shadowMd],
      );

  static BoxDecoration get bottomSheetDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius20)),
      );

  static BoxDecoration get infoCardDecoration => BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(radius16),
        border: Border.all(color: Colors.grey.shade100),
      );

  // ----------------------------
  // Status Helpers
  // ----------------------------
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return infoColor;
      case 'dropped_off':
      case 'completed':
        return successColor;
      case 'no_show':
        return errorColor;
      default:
        return warningColor;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return Icons.person_pin_circle_rounded;
      case 'dropped_off':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'no_show':
        return Icons.person_off_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  static String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return 'PICKED UP';
      case 'dropped_off':
        return 'DROPPED OFF';
      case 'completed':
        return 'COMPLETED';
      case 'no_show':
        return 'NO SHOW';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ----------------------------
  // Text Field Decoration
  // ----------------------------
  static InputDecoration textFieldDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius16),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius16),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      labelStyle: GoogleFonts.inter(
          color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  // ----------------------------
  // Light Theme
  // ----------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(
            color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ----------------------------
  // Dark Theme
  // ----------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: secondaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: Color(0xFF021526),
        background: backgroundDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
        ),
      ),
    );
  }
}