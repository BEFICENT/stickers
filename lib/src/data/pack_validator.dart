import 'dart:io';

import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/media/webp_info.dart';

const int maxPackStickerCount = 30;
const int minWhatsappPackStickerCount = 3;
const int maxAnimatedStickerBytes = 500 * 1024;
const int maxStaticStickerBytes = 100 * 1024;
const int stickerDimension = 512;

class PackValidationException implements Exception {
  final List<String> issues;

  const PackValidationException(this.issues);

  @override
  String toString() => issues.join('\n');
}

class PackValidator {
  const PackValidator();

  Future<List<String>> validate(
    StickerPack pack, {
    bool requireWhatsappMinimum = false,
  }) async {
    final issues = <String>[];
    if (pack.title.trim().isEmpty) issues.add('Pack title cannot be empty.');
    if (pack.author.trim().isEmpty) issues.add('Pack author cannot be empty.');
    if (pack.id.trim().isEmpty) issues.add('Pack identifier cannot be empty.');
    if (pack.stickers.length > maxPackStickerCount) {
      issues.add(
          'A pack cannot contain more than $maxPackStickerCount stickers.');
    }
    if (requireWhatsappMinimum &&
        pack.stickers.length < minWhatsappPackStickerCount) {
      issues.add(
        'WhatsApp requires at least $minWhatsappPackStickerCount stickers in a pack.',
      );
    }

    for (var index = 0; index < pack.stickers.length; index++) {
      final file = File(pack.stickers[index].source);
      if (!await file.exists()) {
        issues.add('Sticker ${index + 1} is missing.');
        continue;
      }
      final size = await file.length();
      final sizeLimit =
          pack.animated ? maxAnimatedStickerBytes : maxStaticStickerBytes;
      if (size > sizeLimit) {
        issues.add(
          'Sticker ${index + 1} exceeds the ${sizeLimit ~/ 1024} KB size limit.',
        );
      }
      try {
        final info = await readWebPInfo(file);
        if (info.width != stickerDimension || info.height != stickerDimension) {
          issues.add('Sticker ${index + 1} must be 512x512 pixels.');
        }
        if (info.animated != pack.animated) {
          issues.add(
            'Sticker ${index + 1} does not match the pack animation type.',
          );
        }
      } on FormatException {
        issues.add('Sticker ${index + 1} is not a valid WebP image.');
      }
    }
    return issues;
  }

  Future<void> validateOrThrow(
    StickerPack pack, {
    bool requireWhatsappMinimum = false,
  }) async {
    final issues = await validate(
      pack,
      requireWhatsappMinimum: requireWhatsappMinimum,
    );
    if (issues.isNotEmpty) throw PackValidationException(issues);
  }
}
