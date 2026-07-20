import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';

void main() {
  late Directory temporaryDirectory;
  late PackRepository repository;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('pack_repository_');
    repository = PackRepository(temporaryDirectory);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('round-trips versioned metadata', () async {
    final packs = <StickerPack>[
      StickerPack(
        'Title',
        'Author',
        'pack_1',
        [
          Sticker('/stickers/one.webp', ['😀'])
        ],
        '3',
        true,
      ),
    ];

    await repository.save(packs);

    final document = jsonDecode(await repository.metadataFile.readAsString());
    expect(document['schemaVersion'], PackRepository.schemaVersion);
    final loaded = await repository.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'pack_1');
    expect(loaded.single.animated, isTrue);
    expect(loaded.single.stickers.single.emojis, ['😀']);
  });

  test('loads legacy list metadata', () async {
    await repository.root.create(recursive: true);
    await repository.metadataFile.writeAsString(jsonEncode([
      {
        'id': 'legacy',
        'title': 'Legacy',
        'author': 'Author',
        'imageDataVersion': '1',
        'animated': false,
        'stickers': <Object?>[],
      }
    ]));

    final loaded = await repository.load();

    expect(loaded.single.id, 'legacy');
  });

  test('recovers valid backup when primary metadata is corrupt', () async {
    await repository.save([
      StickerPack('First', 'Author', 'first', [], '1', false),
    ]);
    await repository.save([
      StickerPack('Second', 'Author', 'second', [], '2', false),
    ]);
    await repository.metadataFile.writeAsString('{broken');

    final loaded = await repository.load();

    expect(loaded.single.id, 'first');
    expect(
      (jsonDecode(await repository.metadataFile.readAsString())['packs']
              as List)
          .single['id'],
      'first',
    );
  });

  test('does not silently accept unsupported schemas', () async {
    await repository.root.create(recursive: true);
    await repository.metadataFile.writeAsString(jsonEncode({
      'schemaVersion': PackRepository.schemaVersion + 1,
      'packs': <Object?>[],
    }));

    expect(repository.load, throwsA(isA<PackRepositoryException>()));
  });

  test('rejects a nonnumeric image data version', () async {
    await repository.root.create(recursive: true);
    await repository.metadataFile.writeAsString(jsonEncode({
      'schemaVersion': PackRepository.schemaVersion,
      'packs': [
        {
          'id': 'invalid-version',
          'title': 'Invalid',
          'author': 'Author',
          'imageDataVersion': 'next',
          'animated': false,
          'stickers': <Object?>[],
        }
      ],
    }));

    expect(repository.load, throwsA(isA<PackRepositoryException>()));
  });

  test('serializes overlapping saves in invocation order', () async {
    final first = repository.save([
      StickerPack('First', 'Author', 'first', [], '1', false),
    ]);
    final second = repository.save([
      StickerPack('Second', 'Author', 'second', [], '2', false),
    ]);

    await Future.wait([first, second]);

    expect((await repository.load()).single.id, 'second');
  });
}
