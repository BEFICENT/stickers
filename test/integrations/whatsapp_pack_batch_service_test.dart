import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/integrations/whatsapp_pack_batch_service.dart';
import 'package:whatsapp_stickers_plus/exceptions.dart';

void main() {
  test('queues packs in order and stops when WhatsApp is cancelled', () async {
    final packs = [
      _pack('first'),
      _pack('existing'),
      _pack('cancel'),
      _pack('last')
    ];
    final sent = <String>[];
    final progress = <String>[];
    final service = WhatsappPackBatchService(
      sender: (pack) async {
        sent.add(pack.id);
        if (pack.id == 'existing') {
          throw WhatsappStickersAlreadyAddedException('already added');
        }
        if (pack.id == 'cancel') {
          throw WhatsappStickersCancelledException('cancelled');
        }
      },
    );

    final result = await service.sendAll(
      packs,
      onProgress: (current, total, pack) =>
          progress.add('$current/$total:${pack.id}'),
    );

    expect(sent, ['first', 'existing', 'cancel']);
    expect(result.added.map((pack) => pack.id), ['first']);
    expect(result.alreadyAdded.map((pack) => pack.id), ['existing']);
    expect(result.failures, isEmpty);
    expect(result.cancelled, isTrue);
    expect(progress, ['1/4:first', '2/4:existing', '3/4:cancel']);
  });

  test('records a failed pack and continues with the queue', () async {
    final packs = [_pack('broken'), _pack('valid')];
    final service = WhatsappPackBatchService(
      sender: (pack) async {
        if (pack.id == 'broken') throw const FormatException('invalid');
      },
    );

    final result = await service.sendAll(packs);

    expect(result.failures.single.pack.id, 'broken');
    expect(result.added.single.id, 'valid');
    expect(result.cancelled, isFalse);
  });
}

StickerPack _pack(String id) => StickerPack(
      id,
      'author',
      id,
      [],
      '1',
      false,
    );
