import 'dart:io';
import 'dart:typed_data';

class WebPInfo {
  final int width;
  final int height;
  final bool animated;

  const WebPInfo({
    required this.width,
    required this.height,
    required this.animated,
  });
}

Future<WebPInfo> readWebPInfo(File file) async {
  return parseWebPInfo(await file.readAsBytes());
}

WebPInfo parseWebPInfo(Uint8List bytes) {
  if (bytes.length < 16 ||
      _ascii(bytes, 0, 4) != 'RIFF' ||
      _ascii(bytes, 8, 4) != 'WEBP') {
    throw const FormatException('File is not a WebP image');
  }

  int? width;
  int? height;
  var animated = false;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunk = _ascii(bytes, offset, 4);
    final size = _uint32le(bytes, offset + 4);
    final dataOffset = offset + 8;
    if (size < 0 || dataOffset + size > bytes.length) {
      throw const FormatException('WebP contains a truncated chunk');
    }

    if (chunk == 'VP8X' && size >= 10) {
      animated = animated || (bytes[dataOffset] & 0x02) != 0;
      width = 1 + _uint24le(bytes, dataOffset + 4);
      height = 1 + _uint24le(bytes, dataOffset + 7);
    } else if (chunk == 'ANIM' || chunk == 'ANMF') {
      animated = true;
    } else if (chunk == 'VP8 ' && size >= 10 && width == null) {
      width = 1 +
          (((bytes[dataOffset + 7] & 0x3f) << 8) | bytes[dataOffset + 6]) -
          1;
      height = 1 +
          (((bytes[dataOffset + 9] & 0x3f) << 8) | bytes[dataOffset + 8]) -
          1;
    } else if (chunk == 'VP8L' && size >= 5 && width == null) {
      if (bytes[dataOffset] != 0x2f) {
        throw const FormatException('Invalid lossless WebP signature');
      }
      width = 1 + bytes[dataOffset + 1] + ((bytes[dataOffset + 2] & 0x3f) << 8);
      height = 1 +
          (bytes[dataOffset + 2] >> 6) +
          (bytes[dataOffset + 3] << 2) +
          ((bytes[dataOffset + 4] & 0x0f) << 10);
    }

    offset = dataOffset + size + (size.isOdd ? 1 : 0);
  }

  if (width == null || height == null) {
    throw const FormatException('WebP dimensions could not be read');
  }
  return WebPInfo(width: width, height: height, animated: animated);
}

String _ascii(Uint8List bytes, int offset, int length) =>
    String.fromCharCodes(bytes.sublist(offset, offset + length));

int _uint24le(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

int _uint32le(Uint8List bytes, int offset) =>
    ByteData.sublistView(bytes).getUint32(offset, Endian.little);
