import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_batch_import.dart';
import 'package:stickers/src/data/sticker_pack.dart';

void main() {
  test('imports packs in order and continues after an invalid archive',
      () async {
    final first = _pack('first');
    final third = _pack('third');
    final progress = <String>[];
    final files = [File('first.zip'), File('invalid.zip'), File('third.zip')];

    final result = await importPackBatch(
      files,
      importer: (file) async {
        switch (path.basename(file.path)) {
          case 'first.zip':
            return PackImportResult(
              packs: [first],
              packsMissingMetadata: [first],
            );
          case 'third.zip':
            return PackImportResult(packs: [third]);
          default:
            throw const FormatException('Invalid pack');
        }
      },
      onProgress: (completed, total) => progress.add('$completed/$total'),
    );

    expect(result.packs, [same(first), same(third)]);
    expect(result.packsMissingMetadata, [same(first)]);
    expect(result.failures, hasLength(1));
    expect(result.failures.single.file.path, 'invalid.zip');
    expect(progress, ['1/3', '2/3', '3/3']);
  });

  test('accepts an empty selection', () async {
    final result = await importPackBatch(
      const <File>[],
      importer: (_) async => throw StateError('should not run'),
    );

    expect(result.packs, isEmpty);
    expect(result.packsMissingMetadata, isEmpty);
    expect(result.failures, isEmpty);
  });
}

StickerPack _pack(String id) => StickerPack(
      id,
      'author',
      id,
      [],
      '1',
      false,
    );
