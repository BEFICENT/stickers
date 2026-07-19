import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/fonts_api/fonts_registry.dart';
import 'package:stickers/src/globals.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  Stopwatch sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  final packageInfoTask =
      PackageInfo.fromPlatform().then((result) => info = result);

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(
      ['Google fonts'],
      'SIL Open Font License\n\n$license',
    );
  });

  final service = SettingsService();
  await service.waitForInit();
  settingsController = SettingsController(service);

  final documentsDirectory = await getApplicationDocumentsDirectory();
  packsDir = "${documentsDirectory.path}/packs";
  configurePackRepository(PackRepository(Directory(packsDir)));
  await Future.wait([
    Directory(packsDir).create(recursive: true),
    createDirs(),
    settingsController.loadSettings(),
    packageInfoTask,
  ]);
  packs = PackStore(await getPacks());
  await FontsRegistry.init();
  debugPrint("Added packs");

  debugPrint("Startup: ${sw.elapsedMilliseconds}ms");

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(StickersApp(settingsController: settingsController));
}

Future<void> createDirs() async {
  await getApplicationCacheDirectory().then((value) async {
    final List<Future> tasks = [];
    cacheDir = "${value.path}/cache";
    exportCacheDir = "${value.path}/cache/exported_packs";
    mediaCacheDir = "${value.path}/cache/media";
    fontsCacheDir = "${value.path}/cache/fonts";
    tasks.addAll([
      Directory(mediaCacheDir).create(recursive: true),
      Directory(exportCacheDir).create(recursive: true),
      Directory(fontsCacheDir).create(recursive: true),
    ]);
    await Future.wait(tasks);
  });
}
