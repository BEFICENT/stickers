import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/constants.dart' as constants;
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_export_service.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/globals.dart' as globals;

void main() {
  late Directory temporaryDirectory;
  late Directory sourceDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('pack_export_');
    sourceDirectory = Directory(path.join(temporaryDirectory.path, 'source'));
    await sourceDirectory.create(recursive: true);
    constants.packsDir = path.join(temporaryDirectory.path, 'packs');
    constants.cacheDir = path.join(temporaryDirectory.path, 'cache', 'files');
    constants.mediaCacheDir =
        path.join(temporaryDirectory.path, 'cache', 'media');
    await Directory(constants.packsDir).create(recursive: true);
    await Directory(constants.mediaCacheDir).create(recursive: true);
    globals.packs = PackStore([]);
    configurePackRepository(PackRepository(Directory(constants.packsDir)));
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('creates a separate, uniquely named archive for every selected pack',
      () async {
    final first = await _createPack(sourceDirectory, 'first', 'Same title');
    final second = await _createPack(sourceDirectory, 'second', 'Same title');
    final service = PackExportService(
      outputDirectory: Directory(path.join(temporaryDirectory.path, 'exports')),
    );

    final archives = await service.createArchives([first, second]);

    expect(archives, hasLength(2));
    expect(path.basename(archives[0].path), 'Same title_1.zip');
    expect(path.basename(archives[1].path), 'Same title_2.zip');
    expect(archives[0].path, isNot(archives[1].path));
    expect(await archives[0].exists(), isTrue);
    expect(await archives[1].exists(), isTrue);
  });

  test('an exported pack can be imported with its details intact', () async {
    final original = await _createPack(sourceDirectory, 'original', 'My pack');
    original.publisherWebsite = 'https://example.com';
    final service = PackExportService(
      outputDirectory: Directory(path.join(temporaryDirectory.path, 'exports')),
    );
    final archive = (await service.createArchives([original])).single;

    final result = await importPack(archive);

    final imported = result.packs.single;
    expect(imported.title, original.title);
    expect(imported.author, original.author);
    expect(imported.publisherWebsite, original.publisherWebsite);
    expect(imported.imageDataVersion, original.imageDataVersion);
    expect(imported.animated, original.animated);
    expect(imported.stickers.single.emojis, original.stickers.single.emojis);
    expect(await File(imported.stickers.single.source).exists(), isTrue);
    expect(await File(imported.trayIcon!).exists(), isTrue);
  });

  test('removes a partial export session when a source file is missing',
      () async {
    final valid = await _createPack(sourceDirectory, 'valid', 'Valid');
    final missing = StickerPack(
      'Missing',
      'Author',
      'missing',
      [
        Sticker(path.join(sourceDirectory.path, 'missing.webp'), ['x'])
      ],
      '1',
      false,
    );
    final exportDirectory =
        Directory(path.join(temporaryDirectory.path, 'exports'));
    final service = PackExportService(outputDirectory: exportDirectory);

    await expectLater(
      service.createArchives([valid, missing]),
      throwsA(isA<FileSystemException>()),
    );

    final remaining = await exportDirectory.list().toList();
    expect(remaining, isEmpty);
  });
}

Future<StickerPack> _createPack(
  Directory directory,
  String id,
  String title,
) async {
  final packDirectory = Directory(path.join(directory.path, id));
  await packDirectory.create(recursive: true);
  final sticker = File(path.join(packDirectory.path, 'sticker.webp'));
  final tray = File(path.join(packDirectory.path, 'tray.webp'));
  await sticker.writeAsBytes(_staticWebP(), flush: true);
  await tray.writeAsBytes(_staticWebP(), flush: true);
  return StickerPack(
    title,
    'Author',
    id,
    [
      Sticker(sticker.path, ['happy'])
    ],
    '7',
    false,
    trayIcon: tray.path,
  );
}

Uint8List _staticWebP() {
  final bytes = Uint8List(30);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  ByteData.sublistView(bytes).setUint32(4, 22, Endian.little);
  bytes.setRange(8, 12, 'WEBP'.codeUnits);
  bytes.setRange(12, 16, 'VP8X'.codeUnits);
  ByteData.sublistView(bytes).setUint32(16, 10, Endian.little);
  _setUint24(bytes, 24, 511);
  _setUint24(bytes, 27, 511);
  return bytes;
}

void _setUint24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}
