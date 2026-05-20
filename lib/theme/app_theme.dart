import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// M3-compliant theme configuration.
/// Uses ColorScheme.fromSeed for dynamic tonal palettes,
/// M3 type scale, shape tokens, and component themes.
class AppTheme {
  // ── Primary UI font (titles, buttons, labels, descriptions)
  static String get _uiFont => GoogleFonts.ibmPlexSansArabic().fontFamily!;

  // ── Local font families (registered in pubspec.yaml)
  static const String alnasakhFont = 'alnasakh';
  static const String uthmanicHafsFont = 'UthmanicHafs';

  // ── M3 Seed Color ─────────────────────────────────────────
  static const Color _seedColor = Color(0xFF10B981); // Emerald green

  /// Returns the correct TextStyle for zekr text based on its font attribute.
  ///   - If isQuranicFont → UthmanicHafs
  ///   - Otherwise → alnasakh (inherits bold/regular from weight)
  static TextStyle zekrStyle({
    required bool isQuranicFont,
    required double fontSize,
    required Color color,
    bool bold = false,
  }) {
    if (isQuranicFont) {
      return TextStyle(
        fontFamily: uthmanicHafsFont,
        fontSize: fontSize,
        height: 2.4,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: alnasakhFont,
      fontSize: fontSize,
      height: 2.2,
      color: color,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  // ── M3 Shape Tokens ───────────────────────────────────────
  // M3 shape: None=0, ExtraSmall=4, Small=8, Medium=12, Large=16, ExtraLarge=28, Full=stadium
  static const double shapeExtraSmall = 4;
  static const double shapeSmall = 8;
  static const double shapeMedium = 12;
  static const double shapeLarge = 16;
  static const double shapeExtraLarge = 28;

  // ── Light Theme ──────────────────────────────────────────
  static ThemeData get lightTheme {
    // M3: Generate full tonal palette from seed
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _uiFont,
      colorScheme: colorScheme,

      // M3: scaffoldBackgroundColor uses colorScheme.surface (not custom)
      scaffoldBackgroundColor: colorScheme.surface,

      // ── M3 AppBar Theme ─────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface, // M3: surface color
        foregroundColor: colorScheme.onSurface, // M3: onSurface
        surfaceTintColor: colorScheme.surfaceTint, // M3: surface tint for elevation
        elevation: 0, // M3: no shadow, uses surfaceTint
        scrolledUnderElevation: 3, // M3: elevation tier 2 when scrolled
      ),

      // ── M3 Card Theme ──────────────────────────────────
      // M3 Filled Card: surfaceContainerHighest, elevation 0
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow, // M3: filled card surface
        elevation: 0, // M3: filled card uses 0 elevation
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeMedium), // M3: Medium shape
        ),
      ),

      // ── M3 Input Decoration (TextField) ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest, // M3: filled text field
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // M3 shape: Small (top corners only for filled)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── M3 Switch Theme ─────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary; // M3: selected thumb
          }
          return colorScheme.outline; // M3: unselected thumb
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary; // M3: selected track
          }
          return colorScheme.surfaceContainerHighest; // M3: unselected track
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline; // M3: unselected outline
        }),
      ),

      // ── M3 IconButton Theme ─────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant, // M3: icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapeExtraLarge), // M3: Full shape
          ),
        ),
      ),

      // ── M3 SnackBar Theme ───────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface, // M3: inverseSurface
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeSmall), // M3: Small shape
        ),
      ),

      // ── M3 Bottom Sheet Theme ───────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow, // M3: surface container low
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapeExtraLarge), // M3: Extra Large top shape
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        showDragHandle: false, // we handle this manually
      ),

      // ── M3 NavigationBar Theme ─────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 2,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.33,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            height: 1.33,
          );
        }),
      ),

      // ── M3 Divider Theme ────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant, // M3: outlineVariant
        thickness: 1,
        space: 1,
      ),

      // ── M3 Progress Indicator Theme ─────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary, // M3: primary
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ── M3 Type Scale ───────────────────────────────────
      textTheme: const TextTheme(
        // M3 Display: 57/64 400, 45/52 400, 36/44 400
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
        // M3 Headline: 32/40 400, 28/36 400, 24/32 400
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, height: 1.25),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 1.29),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.33),
        // M3 Title: 22/28 400, 16/24 500, 14/20 500
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, height: 1.27),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.50),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        // M3 Body: bodyLarge uses alnasakh for zekr text
        bodyLarge: TextStyle(fontFamily: alnasakhFont, fontSize: 16, fontWeight: FontWeight.w400, height: 1.50),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
        // M3 Label: 14/20 500, 12/16 500, 11/16 500
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────
  static ThemeData get darkTheme {
    // M3: Generate dark tonal palette from same seed
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _uiFont,
      colorScheme: colorScheme,

      // M3: scaffoldBackgroundColor uses colorScheme.surface
      scaffoldBackgroundColor: colorScheme.surface,

      // ── M3 AppBar Theme ─────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
      ),

      // ── M3 Card Theme ──────────────────────────────────
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeMedium),
        ),
      ),

      // ── M3 Input Decoration (TextField) ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapeExtraLarge),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── M3 Switch Theme ─────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline;
        }),
      ),

      // ── M3 IconButton Theme ─────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapeExtraLarge),
          ),
        ),
      ),

      // ── M3 SnackBar Theme ───────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeSmall),
        ),
      ),

      // ── M3 Bottom Sheet Theme ───────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapeExtraLarge),
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        showDragHandle: false,
      ),

      // ── M3 NavigationBar Theme ─────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 2,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.33,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            height: 1.33,
          );
        }),
      ),

      // ── M3 Divider Theme ────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── M3 Progress Indicator Theme ─────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ── M3 Type Scale (same sizes, colors from scheme) ──
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, height: 1.25),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 1.29),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.33),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, height: 1.27),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.50),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        bodyLarge: TextStyle(fontFamily: alnasakhFont, fontSize: 16, fontWeight: FontWeight.w400, height: 1.50),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
      ),
    );
  }
}
