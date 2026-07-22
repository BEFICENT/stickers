import 'package:flutter/material.dart';
import 'package:stickers/src/theme/app_themes.dart';

import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  late AppThemePreset _themePreset;

  late bool _quickMode;

  late String _defaultAuthor;
  late String _defaultTitle;
  late String _locale;
  late bool _googleFonts;

  // Whether the user has agreed or not to use the google fonts service
  bool get googleFonts => _googleFonts;

  String get defaultTitle => _defaultTitle;

  String get defaultAuthor => _defaultAuthor;

  String get locale => _locale;

  AppThemePreset get themePreset => _themePreset;

  bool get quickMode => _quickMode;

  Future<void> updateQuickMode(bool quickMode) async {
    if (quickMode == _quickMode) return;
    _quickMode = quickMode;
    notifyListeners();
    await _settingsService.updateQuickMode(quickMode);
  }

  Future<void> updateGoogleFonts(bool googleFonts) async {
    if (googleFonts == _googleFonts) return;
    _googleFonts = googleFonts;
    notifyListeners();
    await _settingsService.updateGoogleFonts(googleFonts);
  }

  Future<void> updateDefaultAuthor(String defaultAuthor) async {
    if (defaultAuthor == _defaultAuthor) return;
    _defaultAuthor = defaultAuthor;
    notifyListeners();
    await _settingsService.updateDefaultAuthor(defaultAuthor);
  }

  Future<void> updateDefaultTitle(String defaultTitle) async {
    if (defaultTitle == _defaultTitle) return;
    _defaultTitle = defaultTitle;
    notifyListeners();
    await _settingsService.updateDefaultTitle(defaultTitle);
  }

  Future<void> updateLocale(String locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _settingsService.updateLocale(locale);
  }

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _themePreset = await _settingsService.themePreset();
    _quickMode = await _settingsService.quickMode();
    _defaultTitle = await _settingsService.defaultTitle();
    _defaultAuthor = await _settingsService.defaultAuthor();
    _locale = await _settingsService.locale();
    _googleFonts = await _settingsService.googleFonts();

    notifyListeners();
  }

  Future<void> updateThemePreset(AppThemePreset newThemePreset) async {
    if (newThemePreset == _themePreset) return;

    _themePreset = newThemePreset;
    notifyListeners();
    await _settingsService.updateThemePreset(newThemePreset);
  }
}
