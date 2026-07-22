import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stickers/src/settings/settings_service.dart';
import 'package:stickers/src/theme/app_themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsService> createService(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final service = SettingsService();
    await service.waitForInit();
    return service;
  }

  test('persists and reloads every supported setting', () async {
    final service = await createService({});

    await service.updateThemePreset(AppThemePreset.oledMint);
    await service.updateQuickMode(true);
    await service.updateDefaultTitle('Favorites');
    await service.updateDefaultAuthor('Author');
    await service.updateLocale('de');
    await service.updateGoogleFonts(true);

    expect(await service.themePreset(), AppThemePreset.oledMint);
    expect(await service.quickMode(), isTrue);
    expect(await service.defaultTitle(), 'Favorites');
    expect(await service.defaultAuthor(), 'Author');
    expect(await service.locale(), 'de');
    expect(await service.googleFonts(), isTrue);
  });

  test('migrates the legacy default pack title key', () async {
    final service = await createService({
      'defaultPackName': 'Legacy title',
    });

    expect(await service.defaultTitle(), 'Legacy title');
    expect(
      (await SharedPreferences.getInstance()).getString('defaultTitle'),
      'Legacy title',
    );
  });

  test('prefers the current default title key over the legacy key', () async {
    final service = await createService({
      'defaultPackName': 'Legacy title',
      'defaultTitle': 'Current title',
    });

    expect(await service.defaultTitle(), 'Current title');
  });

  test('migrates legacy light and dark theme modes', () async {
    final light = await createService({'themeMode': 'light'});
    expect(await light.themePreset(), AppThemePreset.canvas);

    final dark = await createService({'themeMode': 'dark'});
    expect(await dark.themePreset(), AppThemePreset.carbon);

    final system = await createService({'themeMode': 'system'});
    expect(await system.themePreset(), AppThemePreset.system);
  });

  test('falls back to system for an unknown theme preset', () async {
    final service = await createService({'themePreset': 'removed-theme'});

    expect(await service.themePreset(), AppThemePreset.system);
  });
}
