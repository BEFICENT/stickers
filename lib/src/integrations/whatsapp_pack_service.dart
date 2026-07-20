import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:whatsapp_stickers_plus/whatsapp_stickers.dart';

class WhatsappPackService {
  final Directory workingDirectory;
  final PackValidator validator;

  const WhatsappPackService({
    required this.workingDirectory,
    this.validator = const PackValidator(),
  });

  Future<void> send(StickerPack pack) async {
    await validator.validateOrThrow(pack, requireWhatsappMinimum: true);
    await workingDirectory.create(recursive: true);

    final scale = ImageEditorOption()
      ..addOption(const ScaleOption(96, 96))
      ..outputFormat = const OutputFormat.png();
    final generatedTray = await ImageEditor.editFileImageAndGetFile(
      file: File(pack.trayIcon ?? pack.stickers.first.source),
      imageEditorOption: scale,
    );
    if (generatedTray == null) {
      throw StateError('Could not generate the WhatsApp tray icon.');
    }

    final trayFile = File(path.join(
      workingDirectory.path,
      'tray_${pack.id}_${DateTime.now().microsecondsSinceEpoch}.png',
    ));
    await generatedTray.copy(trayFile.path);
    try {
      final whatsappPack = WhatsappStickers(
        identifier: pack.id,
        name: pack.title,
        publisher: pack.author,
        trayImageFileName: WhatsappStickerImage.fromFile(trayFile.path),
        imageDataVersion: pack.imageDataVersion,
        publisherWebsite: pack.publisherWebsite,
        privacyPolicyWebsite: pack.privacyPolicyWebsite,
        licenseAgreementWebsite: pack.licenseAgreementWebsite,
        animatedStickerPack: pack.animated,
      );

      for (final sticker in pack.stickers) {
        whatsappPack.addSticker(
          WhatsappStickerImage.fromFile(sticker.source),
          sticker.emojis,
        );
      }

      debugPrint(
        'Adding ${pack.title} (${pack.id}) v=${pack.imageDataVersion} to WhatsApp',
      );
      await whatsappPack.sendToWhatsApp();
    } finally {
      if (await trayFile.exists()) await trayFile.delete();
      if (await generatedTray.exists()) await generatedTray.delete();
    }
  }
}
