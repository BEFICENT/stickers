import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/integrations/whatsapp_provider_storage.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'whatsapp_provider_storage_test_',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('clears legacy provider metadata once per send session', () async {
    final providerDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}provider',
    );
    final configFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}sticker_packs.json',
    );
    await configFile.writeAsString('stale metadata');
    final storage = WhatsappProviderStorage(
      directory: providerDirectory,
      configFile: configFile,
    );

    await storage.prepareSession();

    expect(await providerDirectory.exists(), isTrue);
    expect(await configFile.exists(), isFalse);

    await configFile.writeAsString('current batch metadata');
    await storage.prepareSession();

    expect(await configFile.readAsString(), 'current batch metadata');
  });

  test('uses a stable filesystem-safe tray path for each pack', () {
    final storage = WhatsappProviderStorage(
      directory: temporaryDirectory,
      configFile: File(
        '${temporaryDirectory.path}${Platform.pathSeparator}sticker_packs.json',
      ),
    );

    final first = storage.trayFileFor('pack/with unsafe characters');
    final repeated = storage.trayFileFor('pack/with unsafe characters');
    final other = storage.trayFileFor('another pack');

    expect(first.path, repeated.path);
    expect(first.path, isNot(other.path));
    expect(first.parent.path, temporaryDirectory.path);
    expect(first.uri.pathSegments.last, isNot(contains('/')));
  });

  test('changes the WhatsApp version when the provider schema changes', () {
    expect(whatsappImageDataVersion('3'), '4');
    expect(whatsappImageDataVersion('1000'), '1001');
  });
}
