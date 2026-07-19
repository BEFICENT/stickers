import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/media/webp_info.dart';

void main() {
  test('reads dimensions and animation flag from VP8X', () {
    final bytes = _vp8x(width: 512, height: 512, animated: true);

    final info = parseWebPInfo(bytes);

    expect(info.width, 512);
    expect(info.height, 512);
    expect(info.animated, isTrue);
  });

  test('rejects truncated chunks', () {
    final bytes = _vp8x(width: 512, height: 512, animated: false);
    bytes[16] = 100;

    expect(() => parseWebPInfo(bytes), throwsFormatException);
  });

  test('rejects non-WebP data', () {
    expect(
      () => parseWebPInfo(Uint8List.fromList(List.filled(20, 0))),
      throwsFormatException,
    );
  });
}

Uint8List _vp8x({
  required int width,
  required int height,
  required bool animated,
}) {
  final bytes = Uint8List(30);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  ByteData.sublistView(bytes).setUint32(4, 22, Endian.little);
  bytes.setRange(8, 12, 'WEBP'.codeUnits);
  bytes.setRange(12, 16, 'VP8X'.codeUnits);
  ByteData.sublistView(bytes).setUint32(16, 10, Endian.little);
  bytes[20] = animated ? 0x02 : 0;
  _setUint24(bytes, 24, width - 1);
  _setUint24(bytes, 27, height - 1);
  return bytes;
}

void _setUint24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}
