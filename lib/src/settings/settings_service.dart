import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stickers/src/theme/app_themes.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  static const _defaultTitleKey = "defaultTitle";
  static const _legacyDefaultTitleKey = "defaultPackName";
  static const _themePresetKey = "themePreset";
  static const _legacyThemeModeKey = "themeMode";

  late SharedPreferences _prefs;
  late Future<SharedPreferences> _pFuture;

  SettingsService() {
    _pFuture = SharedPreferences.getInstance().then((value) => _prefs = value);
  }

  Future waitForInit() async {
    await _pFuture;
  }

  Future<AppThemePreset> themePreset() async {
    final preset = _prefs.getString(_themePresetKey);
    if (preset != null) {
      return AppThemePreset.values.firstWhere(
        (value) => value.name == preset,
        orElse: () => AppThemePreset.system,
      );
    }

    return switch (_prefs.getString(_legacyThemeModeKey)) {
      "light" => AppThemePreset.canvas,
      "dark" => AppThemePreset.carbon,
      _ => AppThemePreset.system,
    };
  }

  Future<bool> quickMode() async => _prefs.getBool("quickMode") ?? false;

  Future<bool> googleFonts() async => _prefs.getBool("googleFonts") ?? false;

  Future<String> defaultTitle() async {
    final title = _prefs.getString(_defaultTitleKey);
    if (title != null) return title;

    final legacyTitle = _prefs.getString(_legacyDefaultTitleKey);
    if (legacyTitle != null) {
      await _persist(
        _prefs.setString(_defaultTitleKey, legacyTitle),
        _defaultTitleKey,
      );
      return legacyTitle;
    }
    return "New sticker pack";
  }

  Future<String> defaultAuthor() async =>
      _prefs.getString("defaultAuthor") ?? "auto-generated";

  Future<String> locale() async => _prefs.getString("locale") ?? _getLocale();

  /// Gets the locale from the system settings if unset in config
  String _getLocale() {
    if (Platform.localeName.startsWith("de")) return "de";
    if (Platform.localeName.startsWith("fr")) return "fr";
    return "en";
  }

  Future<void> updateThemePreset(AppThemePreset preset) async {
    await _persist(
      _prefs.setString(_themePresetKey, preset.name),
      _themePresetKey,
    );
  }

  Future<void> updateQuickMode(bool quickMode) async {
    await _persist(_prefs.setBool("quickMode", quickMode), "quickMode");
  }

  Future<void> updateDefaultTitle(String defaultTitle) async {
    await _persist(
      _prefs.setString(_defaultTitleKey, defaultTitle),
      _defaultTitleKey,
    );
  }

  Future<void> updateDefaultAuthor(String defaultAuthor) async {
    await _persist(
      _prefs.setString("defaultAuthor", defaultAuthor),
      "defaultAuthor",
    );
  }

  Future<void> updateLocale(String locale) async {
    await _persist(_prefs.setString("locale", locale), "locale");
  }

  Future<void> updateGoogleFonts(bool googleFonts) async {
    await _persist(
      _prefs.setBool("googleFonts", googleFonts),
      "googleFonts",
    );
  }

  Future<void> _persist(Future<bool> write, String key) async {
    if (!await write) {
      throw SettingsPersistenceException(key);
    }
  }
}

class SettingsPersistenceException implements Exception {
  final String key;

  const SettingsPersistenceException(this.key);

  @override
  String toString() => "Could not persist setting: $key";
}
