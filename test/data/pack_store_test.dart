import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';

void main() {
  StickerPack pack(String id) => StickerPack(id, 'Author', id, [], '1', false);

  test('notifies when the pack list changes', () {
    final store = PackStore([]);
    var notifications = 0;
    store.addListener(() => notifications++);

    store.add(pack('one'));
    store.removeAt(0);

    expect(notifications, 2);
  });

  test('coalesces a transaction into one notification', () async {
    final store = PackStore([]);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.transaction(() async {
      store.add(pack('one'));
      store.add(pack('two'));
      store.removeAt(0);
    });

    expect(store.single.id, 'two');
    expect(notifications, 1);
  });
}
