import 'package:flutter/material.dart';

// Paleta de colores exacta extraída del diseño Stitch (Tailwind config)
class AppTheme {
  // ─── Colores principales ───────────────────────────────────────
  static const Color primary              = Color(0xFF154212);
  static const Color onPrimary            = Color(0xFFFFFFFF);
  static const Color primaryContainer     = Color(0xFF2D5A27);
  static const Color onPrimaryContainer   = Color(0xFF9DD090);
  static const Color primaryFixed         = Color(0xFFBCF0AE);
  static const Color primaryFixedDim      = Color(0xFFA1D494);
  static const Color inversePrimary       = Color(0xFFA1D494);

  // ─── Colores secundarios ───────────────────────────────────────
  static const Color secondary            = Color(0xFF7D562D);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color secondaryContainer   = Color(0xFFFFCA98);
  static const Color onSecondaryContainer = Color(0xFF7A532A);
  static const Color secondaryFixed       = Color(0xFFFFDCBD);
  static const Color secondaryFixedDim    = Color(0xFFF0BD8B);

  // ─── Colores terciarios ────────────────────────────────────────
  static const Color tertiary             = Color(0xFF6A1F17);
  static const Color onTertiary           = Color(0xFFFFFFFF);
  static const Color tertiaryContainer    = Color(0xFF88352C);
  static const Color tertiaryFixed        = Color(0xFFFFDAD5);
  static const Color tertiaryFixedDim     = Color(0xFFFFB4A9);

  // ─── Superficies ───────────────────────────────────────────────
  static const Color background                = Color(0xFFF9FAF6);
  static const Color surface                   = Color(0xFFF9FAF6);
  static const Color surfaceBright             = Color(0xFFF9FAF6);
  static const Color surfaceDim                = Color(0xFFD9DAD7);
  static const Color surfaceContainerLowest    = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow       = Color(0xFFF3F4F0);
  static const Color surfaceContainer          = Color(0xFFEDEEEA);
  static const Color surfaceContainerHigh      = Color(0xFFE7E9E5);
  static const Color surfaceContainerHighest   = Color(0xFFE2E3DF);
  static const Color surfaceVariant            = Color(0xFFE2E3DF);
  static const Color inverseSurface            = Color(0xFF2E312F);
  static const Color inverseOnSurface          = Color(0xFFF0F1ED);

  // ─── Texto ─────────────────────────────────────────────────────
  static const Color onSurface               = Color(0xFF1A1C1A);
  static const Color onSurfaceVariant        = Color(0xFF42493E);
  static const Color onBackground            = Color(0xFF1A1C1A);
  static const Color outline                 = Color(0xFF72796E);
  static const Color outlineVariant          = Color(0xFFC2C9BB);

  // ─── Error ────────────────────────────────────────────────────
  static const Color error                   = Color(0xFFBA1A1A);
  static const Color onError                 = Color(0xFFFFFFFF);
  static const Color errorContainer          = Color(0xFFFFDAD6);
  static const Color onErrorContainer        = Color(0xFF93000A);

  // Alias de compatibilidad con pantallas existentes
  static const Color textDark   = onSurface;
  static const Color textMedium = onSurfaceVariant;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          secondary: secondary,
          onSecondary: onSecondary,
          secondaryContainer: secondaryContainer,
          onSecondaryContainer: onSecondaryContainer,
          tertiary: tertiary,
          onTertiary: onTertiary,
          tertiaryContainer: tertiaryContainer,
          error: error,
          onError: onError,
          errorContainer: errorContainer,
          onErrorContainer: onErrorContainer,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: outline,
          outlineVariant: outlineVariant,
          inverseSurface: inverseSurface,
          onInverseSurface: inverseOnSurface,
          inversePrimary: inversePrimary,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primary,
          inactiveTrackColor: surfaceVariant,
          thumbColor: primary,
          overlayColor: primary.withAlpha(26),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: surfaceContainerHighest,
        ),
      );
}
