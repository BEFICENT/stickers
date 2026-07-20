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
    final imageDataVersion = int.tryParse(pack.imageDataVersion);
    if (imageDataVersion == null || imageDataVersion < 0) {
      issues.add('Pack image data version must be a non-negative integer.');
    }
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
      issues.addAll(await validateStickerFile(
        file,
        animated: pack.animated,
        label: 'Sticker ${index + 1}',
      ));
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

  Future<List<String>> validateStickerFile(
    File file, {
    required bool animated,
    String label = 'Sticker',
  }) async {
    if (!await file.exists()) return ['$label is missing.'];

    final issues = <String>[];
    final size = await file.length();
    final sizeLimit =
        animated ? maxAnimatedStickerBytes : maxStaticStickerBytes;
    if (size > sizeLimit) {
      issues.add('$label exceeds the ${sizeLimit ~/ 1024} KB size limit.');
    }
    try {
      final info = await readWebPInfo(file);
      if (info.width != stickerDimension || info.height != stickerDimension) {
        issues.add('$label must be 512x512 pixels.');
      }
      if (info.animated != animated) {
        issues.add('$label does not match the pack animation type.');
      }
    } on FormatException {
      issues.add('$label is not a valid WebP image.');
    }
    return issues;
  }

  Future<void> validateStickerFileOrThrow(
    File file, {
    required bool animated,
    String label = 'Sticker',
  }) async {
    final issues = await validateStickerFile(
      file,
      animated: animated,
      label: label,
    );
    if (issues.isNotEmpty) throw PackValidationException(issues);
  }
}
