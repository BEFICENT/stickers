import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppThemePreset { system, canvas, carbon, oledMint, oledEmber }

extension AppThemePresetMode on AppThemePreset {
  ThemeMode get themeMode => switch (this) {
        AppThemePreset.system => ThemeMode.system,
        AppThemePreset.canvas => ThemeMode.light,
        AppThemePreset.carbon ||
        AppThemePreset.oledMint ||
        AppThemePreset.oledEmber =>
          ThemeMode.dark,
      };
}

class AppThemes {
  AppThemes._();

  static final ThemeData canvas = _build(
    brightness: Brightness.light,
    background: const Color(0xfff6f7f9),
    surface: const Color(0xffffffff),
    surfaceLow: const Color(0xffeef1f3),
    surfaceHigh: const Color(0xffe2e7ea),
    onSurface: const Color(0xff1a1d1f),
    primary: const Color(0xff006b5f),
    onPrimary: const Color(0xffffffff),
    primaryContainer: const Color(0xffb9eade),
    onPrimaryContainer: const Color(0xff073e38),
    secondary: const Color(0xffa33f28),
    onSecondary: const Color(0xffffffff),
    secondaryContainer: const Color(0xffffdacf),
    onSecondaryContainer: const Color(0xff5c1c0d),
    tertiary: const Color(0xff3f6381),
    outline: const Color(0xff737b7e),
  );

  static final ThemeData carbon = _build(
    brightness: Brightness.dark,
    background: const Color(0xff111315),
    surface: const Color(0xff171a1c),
    surfaceLow: const Color(0xff1e2225),
    surfaceHigh: const Color(0xff292e32),
    onSurface: const Color(0xffedf1f2),
    primary: const Color(0xff64d9c4),
    onPrimary: const Color(0xff00382f),
    primaryContainer: const Color(0xff11594e),
    onPrimaryContainer: const Color(0xffb9f5e7),
    secondary: const Color(0xffffad95),
    onSecondary: const Color(0xff5f1605),
    secondaryContainer: const Color(0xff78301f),
    onSecondaryContainer: const Color(0xffffd9ce),
    tertiary: const Color(0xffa9c8ea),
    outline: const Color(0xff8a9295),
  );

  static final ThemeData oledMint = _build(
    brightness: Brightness.dark,
    background: const Color(0xff000000),
    surface: const Color(0xff000000),
    surfaceLow: const Color(0xff0a0d0c),
    surfaceHigh: const Color(0xff151a18),
    onSurface: const Color(0xfff1f7f4),
    primary: const Color(0xff55e6b5),
    onPrimary: const Color(0xff003829),
    primaryContainer: const Color(0xff0b503d),
    onPrimaryContainer: const Color(0xffb9f8df),
    secondary: const Color(0xffffb86b),
    onSecondary: const Color(0xff4b2800),
    secondaryContainer: const Color(0xff623b0c),
    onSecondaryContainer: const Color(0xffffddb8),
    tertiary: const Color(0xff77d5df),
    outline: const Color(0xff718079),
    oled: true,
  );

  static final ThemeData oledEmber = _build(
    brightness: Brightness.dark,
    background: const Color(0xff000000),
    surface: const Color(0xff000000),
    surfaceLow: const Color(0xff0e0b0a),
    surfaceHigh: const Color(0xff1c1512),
    onSurface: const Color(0xfffff5f1),
    primary: const Color(0xffff8a65),
    onPrimary: const Color(0xff4b1505),
    primaryContainer: const Color(0xff6f2817),
    onPrimaryContainer: const Color(0xffffd8cc),
    secondary: const Color(0xff5bddc2),
    onSecondary: const Color(0xff00382f),
    secondaryContainer: const Color(0xff105749),
    onSecondaryContainer: const Color(0xffb9f5e7),
    tertiary: const Color(0xffffd166),
    outline: const Color(0xff857772),
    oled: true,
  );

  static ThemeData lightFor(AppThemePreset preset) => canvas;

  static ThemeData darkFor(AppThemePreset preset) => switch (preset) {
        AppThemePreset.oledMint => oledMint,
        AppThemePreset.oledEmber => oledEmber,
        _ => carbon,
      };

  static List<Color> swatches(AppThemePreset preset) => switch (preset) {
        AppThemePreset.system => const [
            Color(0xfff6f7f9),
            Color(0xff006b5f),
            Color(0xff111315),
          ],
        AppThemePreset.canvas => const [
            Color(0xffffffff),
            Color(0xff006b5f),
            Color(0xffa33f28),
          ],
        AppThemePreset.carbon => const [
            Color(0xff111315),
            Color(0xff64d9c4),
            Color(0xffffad95),
          ],
        AppThemePreset.oledMint => const [
            Color(0xff000000),
            Color(0xff55e6b5),
            Color(0xffffb86b),
          ],
        AppThemePreset.oledEmber => const [
            Color(0xff000000),
            Color(0xffff8a65),
            Color(0xff5bddc2),
          ],
      };

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceLow,
    required Color surfaceHigh,
    required Color onSurface,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color secondary,
    required Color onSecondary,
    required Color secondaryContainer,
    required Color onSecondaryContainer,
    required Color tertiary,
    required Color outline,
    bool oled = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceLow,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: Color.alphaBlend(
        onSurface.withValues(alpha: 0.08),
        surfaceHigh,
      ),
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.45),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final textTheme = base.textTheme
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);

    return base.copyWith(
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: oled ? const Color(0xff080a09) : surfaceLow,
        surfaceTintColor: Colors.transparent,
        elevation: oled ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: oled ? const Color(0xff050605) : surfaceLow,
        modalBackgroundColor: oled ? const Color(0xff050605) : surfaceLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(buttonShape)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(buttonShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(buttonShape)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
