import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('pack_validator_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('accepts a structurally valid 512x512 sticker', () async {
    final file = await _writeWebP(temporaryDirectory, animated: false);
    final pack = StickerPack(
      'Pack',
      'Author',
      'pack',
      [
        Sticker(file.path, ['😀'])
      ],
      '1',
      false,
    );

    expect(await const PackValidator().validate(pack), isEmpty);
  });

  test('reports missing stickers and the WhatsApp minimum', () async {
    final pack = StickerPack(
      'Pack',
      'Author',
      'pack',
      [
        Sticker('${temporaryDirectory.path}/missing.webp', ['😀'])
      ],
      '1',
      false,
    );

    final issues = await const PackValidator().validate(
      pack,
      requireWhatsappMinimum: true,
    );

    expect(issues, contains(contains('at least 3')));
    expect(issues, contains(contains('missing')));
  });

  test('rejects animation type mismatches', () async {
    final file = await _writeWebP(temporaryDirectory, animated: true);
    final pack = StickerPack(
      'Pack',
      'Author',
      'pack',
      [
        Sticker(file.path, ['😀'])
      ],
      '1',
      false,
    );

    expect(
      await const PackValidator().validate(pack),
      contains(contains('animation type')),
    );
  });
}

Future<File> _writeWebP(Directory directory, {required bool animated}) async {
  final bytes = Uint8List(30);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  ByteData.sublistView(bytes).setUint32(4, 22, Endian.little);
  bytes.setRange(8, 12, 'WEBP'.codeUnits);
  bytes.setRange(12, 16, 'VP8X'.codeUnits);
  ByteData.sublistView(bytes).setUint32(16, 10, Endian.little);
  bytes[20] = animated ? 0x02 : 0;
  _setUint24(bytes, 24, 511);
  _setUint24(bytes, 27, 511);
  final file = File('${directory.path}/sticker.webp');
  await file.writeAsBytes(bytes);
  return file;
}

void _setUint24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}
