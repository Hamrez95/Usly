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

@immutable
class UslyPalette extends ThemeExtension<UslyPalette> {
  const UslyPalette({
    required this.coral,
    required this.privacy,
    required this.softSurface,
  });

  final Color coral;
  final Color privacy;
  final Color softSurface;

  @override
  UslyPalette copyWith({Color? coral, Color? privacy, Color? softSurface}) {
    return UslyPalette(
      coral: coral ?? this.coral,
      privacy: privacy ?? this.privacy,
      softSurface: softSurface ?? this.softSurface,
    );
  }

  @override
  UslyPalette lerp(covariant UslyPalette? other, double t) {
    if (other == null) return this;
    return UslyPalette(
      coral: Color.lerp(coral, other.coral, t)!,
      privacy: Color.lerp(privacy, other.privacy, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
    );
  }

  static UslyPalette of(BuildContext context) =>
      Theme.of(context).extension<UslyPalette>()!;
}

abstract final class UslySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const hero = 32.0;

  static double pagePadding(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 390 ? lg : xl;
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
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
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
    coral: UslyColors.coralLight,
    privacy: UslyColors.privacyLight,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    canvas: UslyColors.canvasDark,
    surface: UslyColors.surfaceDark,
    ink: UslyColors.inkDark,
    primary: UslyColors.tealDark,
    secondary: UslyColors.saffronDark,
    coral: UslyColors.coralDark,
    privacy: UslyColors.privacyDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color primary,
    required Color secondary,
    required Color coral,
    required Color privacy,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.dark
          ? UslyColors.inkLight
          : Colors.white,
      secondary: secondary,
      onSecondary: UslyColors.inkLight,
      tertiary: coral,
      onTertiary: brightness == Brightness.dark
          ? UslyColors.inkLight
          : Colors.white,
      error: brightness == Brightness.dark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFB3261E),
      onError: brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Vazirmatn',
      fontFamilyFallback: const ['Tahoma', 'Arial'],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        UslyPalette(
          coral: coral,
          privacy: privacy,
          softSurface: Color.alphaBlend(
            primary.withValues(
              alpha: brightness == Brightness.dark ? .10 : .05,
            ),
            surface,
          ),
        ),
      ],
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.34,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.42,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.6,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.75, color: ink),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.7,
          color: ink.withValues(alpha: .82),
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ink.withValues(alpha: .08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: primary.withValues(alpha: .55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primary.withValues(alpha: .06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
