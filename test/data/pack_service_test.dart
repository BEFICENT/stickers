import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_service.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('pack_service_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  PackService createService(
    PackStore store, {
    PackRepository? repository,
  }) {
    return PackService(
      store: store,
      repository: repository ?? PackRepository(temporaryDirectory),
      root: temporaryDirectory,
    );
  }

  test('creates and persists a pack atomically', () async {
    final store = PackStore([]);
    final service = createService(store);
    final pack = _pack();

    await service.createPack(pack);

    expect(store.single, same(pack));
    expect((await PackRepository(temporaryDirectory).load()).single.id, 'pack');
  });

  test('does not persist a pack with an invalid version', () async {
    final store = PackStore([]);
    final service = createService(store);
    final pack = _pack()..imageDataVersion = 'invalid';

    await expectLater(
      service.createPack(pack),
      throwsA(isA<PackValidationException>()),
    );

    expect(store, isEmpty);
    expect(await PackRepository(temporaryDirectory).load(), isEmpty);
  });

  test('rolls back pack details when persistence fails', () async {
    final pack = _pack();
    final store = PackStore([pack]);
    final service = createService(
      store,
      repository: _FailingRepository(temporaryDirectory),
    );

    await expectLater(
      service.updatePack(
        pack,
        const PackDetails(title: 'Changed', author: 'Changed'),
      ),
      throwsA(isA<PackRepositoryException>()),
    );

    expect(pack.title, 'Pack');
    expect(pack.author, 'Author');
    expect(pack.imageDataVersion, '0');
  });

  test('rolls back sticker emojis when persistence fails', () async {
    final pack = _pack(stickers: [
      Sticker('source.webp', ['😀'])
    ]);
    final store = PackStore([pack]);
    final service = createService(
      store,
      repository: _FailingRepository(temporaryDirectory),
    );

    await expectLater(
      service.updateStickerEmojis(pack, 0, ['❤']),
      throwsA(isA<PackRepositoryException>()),
    );

    expect(pack.stickers.single.emojis, ['😀']);
    expect(pack.imageDataVersion, '0');
  });

  test('adds a validated sticker and a new pack in one commit', () async {
    final store = PackStore([]);
    final service = createService(store);
    final pack = _pack();

    await service.addStickerBytes(pack, 0, _webPBytes(animated: false));

    expect(store.single, same(pack));
    expect(pack.stickers, hasLength(1));
    expect(await File(pack.stickers.single.source).exists(), isTrue);
    final loaded = await PackRepository(temporaryDirectory).load();
    expect(loaded.single.stickers, hasLength(1));
  });

  test('rejects invalid generated stickers before mutating the pack', () async {
    final pack = _pack();
    final store = PackStore([pack]);
    final service = createService(store);

    await expectLater(
      service.addStickerBytes(pack, 0, Uint8List.fromList([1, 2, 3])),
      throwsA(isA<PackValidationException>()),
    );

    expect(pack.stickers, isEmpty);
    expect(pack.imageDataVersion, '0');
  });

  test('rejects an invalid version before mutating pack details', () async {
    final pack = _pack()..imageDataVersion = 'invalid';
    final store = PackStore([pack]);
    final service = createService(store);

    await expectLater(
      service.updatePack(
        pack,
        const PackDetails(title: 'Changed', author: 'Changed'),
      ),
      throwsA(isA<FormatException>()),
    );

    expect(pack.title, 'Pack');
    expect(pack.author, 'Author');
    expect(pack.imageDataVersion, 'invalid');
  });
}

StickerPack _pack({List<Sticker>? stickers}) => StickerPack(
      'Pack',
      'Author',
      'pack',
      stickers ?? [],
      '0',
      false,
    );

Uint8List _webPBytes({required bool animated}) {
  final bytes = Uint8List(30);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  ByteData.sublistView(bytes).setUint32(4, 22, Endian.little);
  bytes.setRange(8, 12, 'WEBP'.codeUnits);
  bytes.setRange(12, 16, 'VP8X'.codeUnits);
  ByteData.sublistView(bytes).setUint32(16, 10, Endian.little);
  bytes[20] = animated ? 0x02 : 0;
  _setUint24(bytes, 24, 511);
  _setUint24(bytes, 27, 511);
  return bytes;
}

void _setUint24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}

class _FailingRepository extends PackRepository {
  _FailingRepository(super.root);

  @override
  Future<void> save(List<StickerPack> packs) async {
    throw const PackRepositoryException('Expected test failure');
  }
}
