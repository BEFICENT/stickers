import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/theme/app_themes.dart';

void main() {
  test('OLED themes use true black for the screen and primary surface', () {
    for (final theme in [AppThemes.oledMint, AppThemes.oledEmber]) {
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xff000000));
      expect(theme.canvasColor, const Color(0xff000000));
      expect(theme.colorScheme.surface, const Color(0xff000000));
      expect(
        theme.colorScheme.surfaceContainerLowest,
        const Color(0xff000000),
      );
    }
  });

  test('every preset resolves to the intended platform brightness mode', () {
    expect(AppThemePreset.system.themeMode, ThemeMode.system);
    expect(AppThemePreset.canvas.themeMode, ThemeMode.light);
    expect(AppThemePreset.carbon.themeMode, ThemeMode.dark);
    expect(AppThemePreset.oledMint.themeMode, ThemeMode.dark);
    expect(AppThemePreset.oledEmber.themeMode, ThemeMode.dark);
  });

  test('system mode uses the custom Canvas and Carbon pair', () {
    expect(AppThemes.lightFor(AppThemePreset.system), same(AppThemes.canvas));
    expect(AppThemes.darkFor(AppThemePreset.system), same(AppThemes.carbon));
  });
}
