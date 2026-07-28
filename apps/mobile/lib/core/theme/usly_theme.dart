import 'package:flutter/material.dart';

abstract final class UslyColors {
  static const canvasLight = Color(0xFFF7F4EF);
  static const surfaceLight = Color(0xFFFFFCF8);
  static const inkLight = Color(0xFF17202B);
  static const tealLight = Color(0xFF165B59);
  static const saffronLight = Color(0xFFF2B544);
  static const coralLight = Color(0xFFE66B5B);
  static const privacyLight = Color(0xFF675C8C);

  static const canvasDark = Color(0xFF0E171A);
  static const surfaceDark = Color(0xFF162326);
  static const inkDark = Color(0xFFF5F1E8);
  static const tealDark = Color(0xFF7AD5CE);
  static const saffronDark = Color(0xFFFFD27A);
  static const coralDark = Color(0xFFFFB39F);
  static const privacyDark = Color(0xFFBEB3E7);
}

abstract final class UslyMotion {
  static Duration quick(BuildContext context) =>
      _reduced(context) ? Duration.zero : const Duration(milliseconds: 140);
  static Duration standard(BuildContext context) =>
      _reduced(context) ? Duration.zero : const Duration(milliseconds: 240);
  static Duration reveal(BuildContext context) =>
      _reduced(context) ? Duration.zero : const Duration(milliseconds: 480);

  static bool _reduced(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true || media?.accessibleNavigation == true;
  }
}

abstract final class UslyTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        canvas: UslyColors.canvasLight,
        surface: UslyColors.surfaceLight,
        ink: UslyColors.inkLight,
        primary: UslyColors.tealLight,
        secondary: UslyColors.saffronLight,
        privacy: UslyColors.privacyLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        canvas: UslyColors.canvasDark,
        surface: UslyColors.surfaceDark,
        ink: UslyColors.inkDark,
        primary: UslyColors.tealDark,
        secondary: UslyColors.saffronDark,
        privacy: UslyColors.privacyDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color primary,
    required Color secondary,
    required Color privacy,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.dark ? UslyColors.inkLight : Colors.white,
      secondary: secondary,
      onSecondary: UslyColors.inkLight,
      error: brightness == Brightness.dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: brightness == Brightness.dark ? const Color(0xFF690005) : Colors.white,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamilyFallback: const ['Vazirmatn', 'Tahoma', 'Arial'],
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 34, height: 1.18, fontWeight: FontWeight.w700, color: ink),
        headlineSmall: TextStyle(fontSize: 24, height: 1.35, fontWeight: FontWeight.w700, color: ink),
        titleLarge: TextStyle(fontSize: 20, height: 1.4, fontWeight: FontWeight.w700, color: ink),
        titleMedium: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.7, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.65, color: ink.withValues(alpha: .82)),
        labelLarge: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: ink.withValues(alpha: .08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: primary.withValues(alpha: .55)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primary.withValues(alpha: .06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: privacy.withValues(alpha: .12),
        labelStyle: TextStyle(color: privacy, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
