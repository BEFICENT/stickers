import 'package:whatsapp_stickers_plus/whatsapp_stickers.dart';

class Sticker {
  String source;

  List<String> emojis;

  Sticker(this.source, this.emojis);

  Map<String, dynamic> toJson() {
    return {"source": source, "emojis": List<String>.from(emojis)};
  }

  factory Sticker.fromJson(Map<String, dynamic> json) {
    final source = json["source"];
    final emojis = json["emojis"];
    if (source is! String || source.isEmpty) {
      throw const FormatException("Sticker source must be a non-empty string");
    }
    if (emojis is! List || emojis.any((emoji) => emoji is! String)) {
      throw const FormatException("Sticker emojis must be strings");
    }
    return Sticker(source, emojis.cast<String>().toList());
  }

  WhatsappStickerImage getWhatsappStickerImage() {
    return WhatsappStickerImage.fromFile(source);
  }
}
