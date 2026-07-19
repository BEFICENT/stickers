import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/constants.dart' as constants;
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/globals.dart' as globals;

void main() {
  late Directory temporaryDirectory;
  late StickerPack pack;
  late File stickerFile;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('pack_mutation_');
    constants.packsDir = '${temporaryDirectory.path}/packs';
    final packDirectory = Directory('${constants.packsDir}/pack');
    await packDirectory.create(recursive: true);
    stickerFile = File('${packDirectory.path}/sticker.webp');
    await stickerFile.writeAsString('fixture');
    pack = StickerPack(
      'Pack',
      'Author',
      'pack',
      [
        Sticker(stickerFile.path, ['😀'])
      ],
      '1',
      false,
    );
    globals.packs = PackStore([pack]);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('restores a sticker when metadata persistence fails', () async {
    configurePackRepository(_FailingRepository(Directory(constants.packsDir)));

    await expectLater(
      deleteStickerFromPack(pack, 0),
      throwsA(isA<PackRepositoryException>()),
    );

    expect(pack.stickers.single.source, stickerFile.path);
    expect(pack.imageDataVersion, '1');
    expect(await stickerFile.exists(), isTrue);
  });

  test('restores a pack at its original position when persistence fails',
      () async {
    configurePackRepository(_FailingRepository(Directory(constants.packsDir)));

    await expectLater(
        deletePack(pack), throwsA(isA<PackRepositoryException>()));

    expect(globals.packs.single, same(pack));
    expect(await stickerFile.exists(), isTrue);
  });

  test('removes files only after pack metadata is committed', () async {
    configurePackRepository(PackRepository(Directory(constants.packsDir)));

    await deletePack(pack);

    expect(globals.packs, isEmpty);
    expect(await stickerFile.exists(), isFalse);
    expect(await PackRepository(Directory(constants.packsDir)).load(), isEmpty);
  });
}

class _FailingRepository extends PackRepository {
  _FailingRepository(super.root);

  @override
  Future<void> save(List<StickerPack> packs) async {
    throw const PackRepositoryException('Expected test failure');
  }
}
