import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_editor/image_editor.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/globals.dart';
import 'package:whatsapp_stickers_plus/whatsapp_stickers.dart';

class StickerPack {
  String title;
  String author;
  String id;
  String imageDataVersion;
  bool animated;
  String? publisherWebsite;
  String? privacyPolicyWebsite;
  String? licenseAgreementWebsite;
  List<Sticker> stickers;
  String? trayIcon;

  StickerPack(this.title, this.author, this.id, this.stickers,
      this.imageDataVersion, this.animated,
      {this.trayIcon,
      this.publisherWebsite,
      this.licenseAgreementWebsite,
      this.privacyPolicyWebsite});

  Future<void> sendToWhatsapp() async {
    await const PackValidator().validateOrThrow(
      this,
      requireWhatsappMinimum: true,
    );

    ImageEditorOption scale = ImageEditorOption();
    scale.addOption(const ScaleOption(96, 96));
    scale.outputFormat = const OutputFormat.png();
    File? trayIconFile = await ImageEditor.editFileImageAndGetFile(
      file: File(trayIcon ?? stickers.first.source),
      imageEditorOption: scale,
    );
    trayIconFile = await trayIconFile!.rename("$packsDir/$id/tray.png");

    var stickerPack = WhatsappStickers(
      identifier: id,
      name: title,
      publisher: author,
      trayImageFileName: WhatsappStickerImage.fromFile(trayIconFile.path),
      imageDataVersion: imageDataVersion,
      publisherWebsite: publisherWebsite,
      privacyPolicyWebsite: privacyPolicyWebsite,
      licenseAgreementWebsite: licenseAgreementWebsite,
      animatedStickerPack: animated,
    );

    for (var sticker in stickers) {
      stickerPack.addSticker(sticker.getWhatsappStickerImage(), sticker.emojis);
    }

    debugPrint("Adding $title ($id)  v=$imageDataVersion to Whatsapp");
    await stickerPack.sendToWhatsApp();
  }

  Future<void> onEdit() async {
    final previousVersion = imageDataVersion;
    imageDataVersion = (int.parse(imageDataVersion) + 1).toString();
    try {
      await savePacks(packs);
      packs.notifyChanged();
    } catch (_) {
      imageDataVersion = previousVersion;
      rethrow;
    }
  }

  Map<String, Object?> toJson() {
    return {
      "id": id,
      "title": title,
      "author": author,
      "imageDataVersion": imageDataVersion,
      "animated": animated,
      "stickers": stickers.map((sticker) => sticker.toJson()).toList(),
      "trayIcon": trayIcon,
      "publisherWebsite": publisherWebsite,
      "privacyPolicyWebsite": privacyPolicyWebsite,
      "licenseAgreementWebsite": licenseAgreementWebsite,
    };
  }

  factory StickerPack.fromJson(Map<String, dynamic> json) {
    final title = json["title"];
    final author = json["author"];
    final id = json["id"];
    final stickers = json["stickers"];
    final imageDataVersion = json["imageDataVersion"];
    final animated = json["animated"] ?? false;
    if (title is! String || author is! String || id is! String || id.isEmpty) {
      throw const FormatException("Pack identity fields are invalid");
    }
    if (stickers is! List || imageDataVersion is! String || animated is! bool) {
      throw const FormatException("Pack data has invalid field types");
    }
    return StickerPack(
      title,
      author,
      id,
      stickers
          .map((sticker) =>
              Sticker.fromJson(Map<String, dynamic>.from(sticker as Map)))
          .toList(),
      imageDataVersion,
      animated,
      trayIcon: _optionalString(json, "trayIcon"),
      publisherWebsite: _optionalString(json, "publisherWebsite"),
      privacyPolicyWebsite: _optionalString(json, "privacyPolicyWebsite"),
      licenseAgreementWebsite: _optionalString(json, "licenseAgreementWebsite"),
    );
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException("$key must be a string or null");
  }

  Future<void> setTray(String source) async {
    Directory parent = Directory("$packsDir/$id/");
    File output = File(
        "$packsDir/$id/tray_${DateTime.now().millisecondsSinceEpoch}.webp");
    if (!parent.existsSync()) await parent.create(recursive: true);
    await File(source).copy(output.path);
    final previousTray = trayIcon;
    trayIcon = output.path;
    try {
      await onEdit();
    } catch (_) {
      trayIcon = previousTray;
      if (await output.exists()) await output.delete();
      rethrow;
    }
    if (previousTray != null && previousTray != output.path) {
      final oldFile = File(previousTray);
      if (await oldFile.exists()) await oldFile.delete();
    }
  }
}
