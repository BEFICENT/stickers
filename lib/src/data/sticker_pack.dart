import 'package:stickers/src/data/sticker.dart';

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
    final version =
        imageDataVersion is String ? int.tryParse(imageDataVersion) : null;
    if (stickers is! List ||
        version == null ||
        version < 0 ||
        animated is! bool) {
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
}
