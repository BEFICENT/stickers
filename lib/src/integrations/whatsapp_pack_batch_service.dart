import 'package:stickers/src/data/sticker_pack.dart';
import 'package:whatsapp_stickers_plus/exceptions.dart';

typedef WhatsappPackSender = Future<void> Function(StickerPack pack);
typedef WhatsappPackSendProgress = void Function(
  int current,
  int total,
  StickerPack pack,
);

class WhatsappPackSendFailure {
  final StickerPack pack;
  final Exception error;
  final StackTrace stackTrace;

  const WhatsappPackSendFailure({
    required this.pack,
    required this.error,
    required this.stackTrace,
  });
}

class WhatsappPackBatchResult {
  final List<StickerPack> added;
  final List<StickerPack> alreadyAdded;
  final List<WhatsappPackSendFailure> failures;
  final bool cancelled;

  const WhatsappPackBatchResult({
    required this.added,
    required this.alreadyAdded,
    required this.failures,
    required this.cancelled,
  });
}

class WhatsappPackBatchService {
  final WhatsappPackSender sender;

  const WhatsappPackBatchService({required this.sender});

  Future<WhatsappPackBatchResult> sendAll(
    Iterable<StickerPack> sourcePacks, {
    WhatsappPackSendProgress? onProgress,
  }) async {
    final packs = sourcePacks.toList(growable: false);
    final added = <StickerPack>[];
    final alreadyAdded = <StickerPack>[];
    final failures = <WhatsappPackSendFailure>[];

    for (var index = 0; index < packs.length; index++) {
      final pack = packs[index];
      onProgress?.call(index + 1, packs.length, pack);
      try {
        await sender(pack);
        added.add(pack);
      } on WhatsappStickersAlreadyAddedException {
        alreadyAdded.add(pack);
      } on WhatsappStickersCancelledException {
        return WhatsappPackBatchResult(
          added: added,
          alreadyAdded: alreadyAdded,
          failures: failures,
          cancelled: true,
        );
      } on Exception catch (error, stackTrace) {
        failures.add(
          WhatsappPackSendFailure(
            pack: pack,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return WhatsappPackBatchResult(
      added: added,
      alreadyAdded: alreadyAdded,
      failures: failures,
      cancelled: false,
    );
  }
}
