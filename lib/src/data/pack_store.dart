import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:stickers/src/data/sticker_pack.dart';

class PackStore extends ListBase<StickerPack> with ChangeNotifier {
  final List<StickerPack> _items;
  int _transactionDepth = 0;
  bool _changedInTransaction = false;

  PackStore(Iterable<StickerPack> packs) : _items = List.of(packs);

  @override
  int get length => _items.length;

  @override
  set length(int value) {
    if (value == _items.length) return;
    _items.length = value;
    _markChanged();
  }

  @override
  StickerPack operator [](int index) => _items[index];

  @override
  void operator []=(int index, StickerPack value) {
    _items[index] = value;
    _markChanged();
  }

  @override
  void add(StickerPack element) {
    _items.add(element);
    _markChanged();
  }

  @override
  void insert(int index, StickerPack element) {
    _items.insert(index, element);
    _markChanged();
  }

  @override
  bool remove(Object? element) {
    final removed = _items.remove(element);
    if (removed) _markChanged();
    return removed;
  }

  @override
  StickerPack removeAt(int index) {
    final removed = _items.removeAt(index);
    _markChanged();
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    if (start == end) return;
    _items.removeRange(start, end);
    _markChanged();
  }

  void notifyChanged() => _markChanged();

  Future<T> transaction<T>(Future<T> Function() action) async {
    _transactionDepth++;
    try {
      return await action();
    } finally {
      _transactionDepth--;
      if (_transactionDepth == 0 && _changedInTransaction) {
        _changedInTransaction = false;
        notifyListeners();
      }
    }
  }

  void _markChanged() {
    if (_transactionDepth > 0) {
      _changedInTransaction = true;
    } else {
      notifyListeners();
    }
  }
}
