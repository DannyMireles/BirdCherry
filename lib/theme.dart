import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// BirdCherry design system.
///
/// Clean, warm-minimalist palette: an off-white canvas, near-black green ink,
/// and a single cherry accent. Display type is Fraunces (a little playful),
/// UI type is Inter (quiet and legible).
abstract final class BcColors {
  static const ink = Color(0xFF16211B); // near-black green
  static const inkSoft = Color(0xFF45524A);
  static const muted = Color(0xFF7C867E);
  static const canvas = Color(0xFFFAF7F1); // warm off-white
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE9E4DA);
  static const cherry = Color(0xFFC9473F); // primary accent
  static const cherryDeep = Color(0xFFA33630);
  static const leaf = Color(0xFF2F5D45); // secondary
  static const leafSoft = Color(0xFFE3EBE2);
  static const cream = Color(0xFFF2EDE3);
  static const gold = Color(0xFFC7842C);

  // Rarity scale.
  static const common = Color(0xFF6B8F71);
  static const uncommon = Color(0xFF4A7BA6);
  static const rare = Color(0xFFC7842C);
  static const legendary = Color(0xFF7B5EA7);
}

abstract final class BcTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BcColors.cherry,
        primary: BcColors.cherry,
        secondary: BcColors.leaf,
        surface: BcColors.canvas,
        onSurface: BcColors.ink,
      ),
      scaffoldBackgroundColor: BcColors.canvas,
    );

    final body = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: BcColors.ink,
      displayColor: BcColors.ink,
    );
    final text = body.copyWith(
      displayLarge: GoogleFonts.fraunces(
          fontSize: 44, fontWeight: FontWeight.w600, color: BcColors.ink, height: 1.05),
      displayMedium: GoogleFonts.fraunces(
          fontSize: 32, fontWeight: FontWeight.w600, color: BcColors.ink, height: 1.1),
      displaySmall: GoogleFonts.fraunces(
          fontSize: 26, fontWeight: FontWeight.w600, color: BcColors.ink, height: 1.15),
      headlineMedium: GoogleFonts.fraunces(
          fontSize: 22, fontWeight: FontWeight.w600, color: BcColors.ink),
      headlineSmall: GoogleFonts.fraunces(
          fontSize: 19, fontWeight: FontWeight.w600, color: BcColors.ink),
      titleLarge: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w700, color: BcColors.ink, letterSpacing: -0.2),
      titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600, color: BcColors.ink, letterSpacing: -0.1),
      titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: BcColors.inkSoft),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: BcColors.ink, height: 1.45),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: BcColors.inkSoft, height: 1.45),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: BcColors.muted, height: 1.35),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: BcColors.muted, letterSpacing: 0.4),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: BcColors.muted, letterSpacing: 0.8),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: BcColors.canvas,
        foregroundColor: BcColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: const CardThemeData(
        color: BcColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: BcColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: BcColors.line, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: BcColors.card,
        selectedColor: BcColors.ink,
        side: const BorderSide(color: BcColors.line),
        labelStyle: text.labelLarge?.copyWith(color: BcColors.ink),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: Colors.white),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BcColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BcColors.ink,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: BcColors.line),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BcColors.cherry,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BcColors.card,
        hintStyle: text.bodyMedium?.copyWith(color: BcColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BcColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BcColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BcColors.ink, width: 1.4),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BcColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BcColors.ink,
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

/// Small haptics helper so every interactive surface feels consistent.
abstract final class Haptic {
  /// Light tick for selections, toggles, chips.
  static void tick() => HapticFeedback.selectionClick();

  /// Soft thump for opening sheets / primary taps.
  static void tap() => HapticFeedback.lightImpact();

  /// Medium for confirmations.
  static void confirm() => HapticFeedback.mediumImpact();

  /// Heavy for celebrations (new sighting, badge unlock).
  static void celebrate() => HapticFeedback.heavyImpact();
}
