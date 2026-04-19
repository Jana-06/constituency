import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFFFF6B35);
  static const saffron = Color(0xFFFF8C42);
  static const green = Color(0xFF1C8C5E);

  static const saffronPrimary = Color(0xFFFF6B35);
  static const lightGreen = Color(0xFF52B788);
  static const darkGray = Color(0xFF111111);
  static const borderGray = Color(0xFFE8E1D9);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return _baseTheme(
      ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFFFFCF8),
      ),
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return _baseTheme(
      ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
      ),
      brightness: Brightness.dark,
    );
  }

  static ThemeData _baseTheme(ThemeData base, {required Brightness brightness}) {
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w800),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w800),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(),
      bodyMedium: GoogleFonts.inter(),
      bodySmall: GoogleFonts.inter(),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ).apply(
      bodyColor: brightness == Brightness.dark ? Colors.white : Colors.black,
      displayColor: brightness == Brightness.dark ? Colors.white : Colors.black,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: brightness == Brightness.dark ? base.colorScheme.surface : const Color(0xFFFFFCF8),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark ? base.colorScheme.surface : Colors.white,
        indicatorColor: base.colorScheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(
            color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelMedium?.copyWith(color: brightness == Brightness.dark ? Colors.white : Colors.black),
        selectedColor: base.colorScheme.primary.withValues(alpha: 0.2),
        backgroundColor: brightness == Brightness.dark ? base.colorScheme.surfaceContainerHighest : const Color(0xFFF7F2EC),
        side: BorderSide(color: base.colorScheme.outlineVariant),
      ),
       cardTheme: CardThemeData(
         elevation: 0,
         color: brightness == Brightness.dark ? base.colorScheme.surfaceContainerHighest : Colors.white,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(14),
           side: BorderSide(color: base.colorScheme.outlineVariant),
         ),
       ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? base.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
            : const Color(0xFFFDF8F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outlineVariant),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: brightness == Brightness.dark ? Colors.white : Colors.black),
        hintStyle: textTheme.bodyMedium?.copyWith(color: brightness == Brightness.dark ? Colors.white70 : Colors.black54),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          foregroundColor: Colors.black,
          backgroundColor: base.colorScheme.primaryContainer,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          foregroundColor: Colors.black,
          side: BorderSide(color: base.colorScheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: const DialogThemeData(elevation: 3),
    );
  }
}

class TamilText extends StatelessWidget {
  const TamilText(this.text, {super.key, this.style, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansTamil(textStyle: style),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class BlurredAppBarBackground extends StatelessWidget {
  const BlurredAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

