import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

enum SourceMediaKind {
  image,
  gif,
  video,
  packArchive,
  unsupported,
}

extension SourceMediaKindProperties on SourceMediaKind {
  bool get isAnimated =>
      this == SourceMediaKind.gif || this == SourceMediaKind.video;
}

class MediaDescriptor {
  final String path;
  final SourceMediaKind kind;

  const MediaDescriptor({required this.path, required this.kind});
}

class MediaProbe {
  static const _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.bmp',
    '.heic',
    '.heif',
    '.avif',
  };
  static const _videoExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.3gp',
    '.3gpp',
    '.webm',
    '.mkv',
  };
  static const _archiveExtensions = {'.stickify', '.zip', '.wastickers'};

  const MediaProbe();

  Future<MediaDescriptor> probe(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Media file does not exist', file.path);
    }
    final handle = await file.open();
    try {
      final length = await handle.length();
      final header = await handle.read(length < 32 ? length : 32);
      return MediaDescriptor(
        path: file.path,
        kind: _kindFromHeader(header, path.extension(file.path).toLowerCase()),
      );
    } finally {
      await handle.close();
    }
  }

  SourceMediaKind _kindFromHeader(Uint8List header, String extension) {
    if (_startsWithAscii(header, 'GIF87a') ||
        _startsWithAscii(header, 'GIF89a')) {
      return SourceMediaKind.gif;
    }
    if (_startsWithAscii(header, 'RIFF') && _asciiAt(header, 8, 4) == 'WEBP') {
      return SourceMediaKind.image;
    }
    if (_startsWith(header, const [0x89, 0x50, 0x4e, 0x47]) ||
        _startsWith(header, const [0xff, 0xd8, 0xff]) ||
        _startsWithAscii(header, 'BM')) {
      return SourceMediaKind.image;
    }
    if (_startsWith(header, const [0x1a, 0x45, 0xdf, 0xa3])) {
      return SourceMediaKind.video;
    }
    if (_startsWith(header, const [0x50, 0x4b, 0x03, 0x04])) {
      return SourceMediaKind.packArchive;
    }
    if (_asciiAt(header, 4, 4) == 'ftyp') {
      final brand = _asciiAt(header, 8, 4);
      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'hevc' ||
          brand == 'hevx' ||
          brand == 'mif1' ||
          brand == 'msf1' ||
          brand == 'avif' ||
          brand == 'avis') {
        return SourceMediaKind.image;
      }
      return SourceMediaKind.video;
    }

    if (extension == '.gif') return SourceMediaKind.gif;
    if (_imageExtensions.contains(extension)) return SourceMediaKind.image;
    if (_videoExtensions.contains(extension)) return SourceMediaKind.video;
    if (_archiveExtensions.contains(extension)) {
      return SourceMediaKind.packArchive;
    }
    return SourceMediaKind.unsupported;
  }

  bool _startsWithAscii(Uint8List bytes, String value) =>
      _asciiAt(bytes, 0, value.length) == value;

  bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }

  String _asciiAt(Uint8List bytes, int offset, int length) {
    if (bytes.length < offset + length) return '';
    return ascii.decode(bytes.sublist(offset, offset + length),
        allowInvalid: true);
  }
}
