import 'package:flutter/services.dart';

class SharedPackMetadata {
  final String title;
  final String author;

  const SharedPackMetadata({required this.title, required this.author});
}

abstract interface class SharedPackMetadataResolver {
  Future<SharedPackMetadata?> resolve(String trayFileName);
}

class StickerPackSourceReference {
  final String authority;
  final String identifier;

  const StickerPackSourceReference({
    required this.authority,
    required this.identifier,
  });
}

class PlatformSharedPackMetadataResolver implements SharedPackMetadataResolver {
  static const _channel = MethodChannel('de.loicezt.stickers/methods');
  static final _trayNamePattern = RegExp(
    r'^([A-Za-z0-9_.]+\.stickercontentprovider) (.+)\.png$',
    caseSensitive: false,
  );

  const PlatformSharedPackMetadataResolver();

  static StickerPackSourceReference? sourceFromTrayFileName(String fileName) {
    final match = _trayNamePattern.firstMatch(fileName);
    if (match == null) return null;
    return StickerPackSourceReference(
      authority: match.group(1)!,
      identifier: match.group(2)!,
    );
  }

  @override
  Future<SharedPackMetadata?> resolve(String trayFileName) async {
    final source = sourceFromTrayFileName(trayFileName);
    if (source == null) return null;
    try {
      final result = await _channel.invokeMapMethod<String, String>(
        'resolveStickerPackMetadata',
        {
          'authority': source.authority,
          'identifier': source.identifier,
        },
      );
      final title = result?['title']?.trim();
      final author = result?['author']?.trim();
      if (title == null || title.isEmpty || author == null || author.isEmpty) {
        return null;
      }
      return SharedPackMetadata(title: title, author: author);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
