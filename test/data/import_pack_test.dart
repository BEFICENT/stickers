import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/constants.dart' as constants;
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/globals.dart' as globals;

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('pack_import_');
    constants.packsDir = '${temporaryDirectory.path}/packs';
    constants.cacheDir = '${temporaryDirectory.path}/app_cache/cache';
    constants.mediaCacheDir = '${temporaryDirectory.path}/app_cache/media';
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

  test('ignores an archive-controlled pack identifier', () async {
    final archive = await _createPackArchive(
      temporaryDirectory,
      id: '../../untrusted',
    );

    await importPack(archive);

    expect(globals.packs, hasLength(1));
    final imported = globals.packs.single;
    expect(imported.id, startsWith('pack_'));
    expect(imported.id, isNot(contains('..')));
    expect(
      path.isWithin(
        path.normalize(constants.packsDir),
        path.normalize(imported.stickers.single.source),
      ),
      isTrue,
    );
    expect(await File(imported.stickers.single.source).exists(), isTrue);
  });

  test('rolls back files and memory when metadata cannot be saved', () async {
    configurePackRepository(_FailingRepository(Directory(constants.packsDir)));
    final archive = await _createPackArchive(temporaryDirectory, id: 'pack');

    await expectLater(
        importPack(archive), throwsA(isA<PackRepositoryException>()));

    expect(globals.packs, isEmpty);
    final installed = await Directory(constants.packsDir)
        .list()
        .where((entity) => entity is Directory)
        .toList();
    expect(installed, isEmpty);
  });

  test('imports a metadata-less pack shared by WhatsApp as a generic zip',
      () async {
    final archive = await _createWhatsAppSharedArchive(temporaryDirectory);

    final result = await importPack(archive);

    expect(globals.packs, hasLength(1));
    final imported = globals.packs.single;
    expect(result.packs.single, same(imported));
    expect(result.packsMissingMetadata.single, same(imported));
    expect(imported.title, 'Imported sticker pack');
    expect(imported.author, 'Imported from WhatsApp');
    expect(imported.animated, isFalse);
    expect(imported.stickers, hasLength(3));
    expect(imported.trayIcon, isNotNull);
    expect(await File(imported.trayIcon!).exists(), isTrue);
    for (var index = 0; index < imported.stickers.length; index++) {
      final bytes = await File(imported.stickers[index].source).readAsBytes();
      expect(bytes[23], index);
    }
  });

  test('retains legacy wastickers metadata when present', () async {
    final archive = await _createWhatsAppSharedArchive(
      temporaryDirectory,
      title: 'Legacy title',
      author: 'Legacy author',
      extension: 'wastickers',
    );

    final result = await importPack(archive);

    expect(globals.packs.single.title, 'Legacy title');
    expect(globals.packs.single.author, 'Legacy author');
    expect(result.packsMissingMetadata, isEmpty);
  });
}

class _FailingRepository extends PackRepository {
  _FailingRepository(super.root);

  @override
  Future<void> save(List<StickerPack> packs) async {
    throw const PackRepositoryException('Expected test failure');
  }
}

Future<File> _createPackArchive(
  Directory directory, {
  required String id,
}) async {
  final document = {
    'id': id,
    'title': 'Imported',
    'author': 'Author',
    'imageDataVersion': '1',
    'animated': false,
    'stickers': [
      {
        'source': 'sticker.webp',
        'emojis': ['😀'],
      }
    ],
  };
  final archive = Archive()
    ..addFile(ArchiveFile.string('pack.json', jsonEncode(document)))
    ..addFile(ArchiveFile('sticker.webp', 30, _staticWebP()));
  final file = File('${directory.path}/pack.zip');
  final output = OutputFileStream(file.path);
  ZipEncoder().encode(archive, output: output);
  await output.close();
  return file;
}

Future<File> _createWhatsAppSharedArchive(
  Directory directory, {
  String? title,
  String? author,
  String extension = 'zip',
}) async {
  final archive = Archive();
  for (final index in [2, 0, 1]) {
    final sticker = _staticWebP()..[23] = index;
    archive.addFile(
      ArchiveFile(
        '${index.toString().padLeft(2, '0')}_content.webp',
        sticker.length,
        sticker,
      ),
    );
  }
  archive.addFile(
    ArchiveFile(
      'provider pack.png',
      8,
      Uint8List.fromList(const [137, 80, 78, 71, 13, 10, 26, 10]),
    ),
  );
  if (title != null) archive.addFile(ArchiveFile.string('title.txt', title));
  if (author != null) {
    archive.addFile(ArchiveFile.string('author.txt', author));
  }

  final file = File('${directory.path}/shared.$extension');
  final output = OutputFileStream(file.path);
  ZipEncoder().encode(archive, output: output);
  await output.close();
  return file;
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
