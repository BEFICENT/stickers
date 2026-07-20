import 'package:stickers/src/batch/batch_import_queue.dart';
import 'package:stickers/src/data/sticker_pack.dart';

enum MediaType { video, picture, gif }

class EditArguments {
  final StickerPack pack;

  /// Index 30 targets the pack tray icon.
  final int index;
  final String mediaPath;
  final MediaType type;
  final Duration trimStart;
  final Duration? trimEnd;
  final BatchImportQueue? batchQueue;

  const EditArguments({
    required this.pack,
    required this.index,
    required this.mediaPath,
    this.type = MediaType.picture,
    this.trimStart = Duration.zero,
    this.trimEnd,
    this.batchQueue,
  });
}
