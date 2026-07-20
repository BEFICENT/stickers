import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';

class PackDetails {
  final String title;
  final String author;
  final String? publisherWebsite;
  final String? privacyPolicyWebsite;
  final String? licenseAgreementWebsite;

  const PackDetails({
    required this.title,
    required this.author,
    this.publisherWebsite,
    this.privacyPolicyWebsite,
    this.licenseAgreementWebsite,
  });
}

class PackService {
  final PackStore store;
  final PackRepository repository;
  final Directory root;
  final PackValidator validator;

  PackService({
    required this.store,
    required this.repository,
    required this.root,
    this.validator = const PackValidator(),
  });

  Future<void> createPack(StickerPack pack) async {
    if (store.any((existing) => existing.id == pack.id)) {
      throw StateError('A pack with identifier ${pack.id} already exists.');
    }
    await validator.validateOrThrow(pack);
    await store.transaction(() async {
      store.add(pack);
      try {
        await repository.save(store);
      } catch (_) {
        store.remove(pack);
        rethrow;
      }
    });
  }

  Future<void> updatePack(StickerPack pack, PackDetails details) async {
    final previous = PackDetails(
      title: pack.title,
      author: pack.author,
      publisherWebsite: pack.publisherWebsite,
      privacyPolicyWebsite: pack.privacyPolicyWebsite,
      licenseAgreementWebsite: pack.licenseAgreementWebsite,
    );
    final previousVersion = pack.imageDataVersion;
    final nextVersion = _nextVersion(pack);
    _applyDetails(pack, details);
    pack.imageDataVersion = nextVersion;
    try {
      await repository.save(store);
      store.notifyChanged();
    } catch (_) {
      _applyDetails(pack, previous);
      pack.imageDataVersion = previousVersion;
      rethrow;
    }
  }

  Future<void> updateStickerEmojis(
    StickerPack pack,
    int index,
    List<String> emojis,
  ) async {
    final sticker = pack.stickers[index];
    final previousEmojis = List<String>.from(sticker.emojis);
    final previousVersion = pack.imageDataVersion;
    final nextVersion = _nextVersion(pack);
    sticker.emojis = List<String>.from(emojis);
    pack.imageDataVersion = nextVersion;
    try {
      await repository.save(store);
      store.notifyChanged();
    } catch (_) {
      sticker.emojis = previousEmojis;
      pack.imageDataVersion = previousVersion;
      rethrow;
    }
  }

  Future<void> addStickerBytes(
    StickerPack pack,
    int index,
    Uint8List data,
  ) async {
    await validator.validateOrThrow(pack);
    if (index == maxPackStickerCount) {
      await _setTrayBytes(pack, data);
      return;
    }
    if (pack.stickers.length >= maxPackStickerCount) {
      throw const PackValidationException([
        'A pack cannot contain more than 30 stickers.',
      ]);
    }
    final nextVersion = _nextVersion(pack);

    final directory = Directory(path.join(root.path, pack.id));
    await directory.create(recursive: true);
    final output = File(path.join(
      directory.path,
      'sticker_${index}_${DateTime.now().microsecondsSinceEpoch}.webp',
    ));
    await output.writeAsBytes(data, flush: true);

    try {
      await validator.validateStickerFileOrThrow(
        output,
        animated: pack.animated,
      );
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    }

    final sticker = Sticker(output.path, ['❤']);
    final previousVersion = pack.imageDataVersion;
    final isNewPack = !store.contains(pack);
    await store.transaction(() async {
      pack.stickers.add(sticker);
      if (isNewPack) store.add(pack);
      pack.imageDataVersion = nextVersion;
      try {
        await repository.save(store);
        if (!isNewPack) store.notifyChanged();
      } catch (_) {
        pack.stickers.remove(sticker);
        if (isNewPack) store.remove(pack);
        pack.imageDataVersion = previousVersion;
        if (await output.exists()) await output.delete();
        rethrow;
      }
    });
  }

  Future<void> setTrayFromFile(StickerPack pack, File source) async {
    final directory = Directory(path.join(root.path, pack.id));
    await directory.create(recursive: true);
    final output = File(path.join(
      directory.path,
      'tray_${DateTime.now().microsecondsSinceEpoch}.webp',
    ));
    await source.copy(output.path);
    await _commitTray(pack, output);
  }

  Future<void> deleteSticker(StickerPack pack, int index) async {
    final sticker = pack.stickers[index];
    final previousVersion = pack.imageDataVersion;
    final nextVersion = _nextVersion(pack);
    pack.stickers.removeAt(index);
    pack.imageDataVersion = nextVersion;
    try {
      await repository.save(store);
      store.notifyChanged();
    } catch (_) {
      pack.stickers.insert(index, sticker);
      pack.imageDataVersion = previousVersion;
      rethrow;
    }

    final file = File(sticker.source);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException catch (error) {
        debugPrint('Failed to clean deleted sticker file: $error');
      }
    }
  }

  Future<void> deletePack(StickerPack pack) async {
    final index = store.indexOf(pack);
    if (index < 0) return;
    await store.transaction(() async {
      store.removeAt(index);
      try {
        await repository.save(store);
      } catch (_) {
        store.insert(index, pack);
        rethrow;
      }
    });

    final directory = Directory(path.join(root.path, pack.id));
    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException catch (error) {
        debugPrint('Failed to clean deleted pack directory: $error');
      }
    }
  }

  Future<void> _setTrayBytes(StickerPack pack, Uint8List data) async {
    final directory = Directory(path.join(root.path, pack.id));
    await directory.create(recursive: true);
    final output = File(path.join(
      directory.path,
      'tray_${DateTime.now().microsecondsSinceEpoch}.webp',
    ));
    await output.writeAsBytes(data, flush: true);
    await _commitTray(pack, output);
  }

  Future<void> _commitTray(StickerPack pack, File output) async {
    final previousTray = pack.trayIcon;
    final previousVersion = pack.imageDataVersion;
    late final String nextVersion;
    try {
      nextVersion = _nextVersion(pack);
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    }
    pack.trayIcon = output.path;
    pack.imageDataVersion = nextVersion;
    try {
      await repository.save(store);
      store.notifyChanged();
    } catch (_) {
      pack.trayIcon = previousTray;
      pack.imageDataVersion = previousVersion;
      if (await output.exists()) await output.delete();
      rethrow;
    }

    if (previousTray != null && previousTray != output.path) {
      final oldFile = File(previousTray);
      if (await oldFile.exists()) await oldFile.delete();
    }
  }

  void _applyDetails(StickerPack pack, PackDetails details) {
    pack.title = details.title;
    pack.author = details.author;
    pack.publisherWebsite = _emptyToNull(details.publisherWebsite);
    pack.privacyPolicyWebsite = _emptyToNull(details.privacyPolicyWebsite);
    pack.licenseAgreementWebsite =
        _emptyToNull(details.licenseAgreementWebsite);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _nextVersion(StickerPack pack) {
    final version = int.tryParse(pack.imageDataVersion);
    if (version == null || version < 0) {
      throw const FormatException('Pack image data version is invalid.');
    }
    return (version + 1).toString();
  }
}
