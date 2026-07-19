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
