import 'dart:convert';
import 'dart:io';

import 'package:stickers/src/data/sticker_pack.dart';

class PackRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const PackRepositoryException(this.message, [this.cause]);

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

class PackRepository {
  static const int schemaVersion = 1;

  final Directory root;
  Future<void> _pendingWrite = Future.value();

  PackRepository(this.root);

  File get metadataFile => File('${root.path}/packs.json');
  File get backupFile => File('${root.path}/packs.json.bak');
  File get temporaryFile => File('${root.path}/packs.json.tmp');

  Future<List<StickerPack>> load() async {
    await root.create(recursive: true);
    if (!await metadataFile.exists()) return <StickerPack>[];

    try {
      return await _read(metadataFile);
    } catch (primaryError) {
      if (!await backupFile.exists()) {
        throw PackRepositoryException(
          'Pack metadata is unreadable and no backup is available',
          primaryError,
        );
      }

      try {
        final recovered = await _read(backupFile);
        await _replaceFile(backupFile, metadataFile, preserveSource: true);
        return recovered;
      } catch (backupError) {
        throw PackRepositoryException(
          'Pack metadata and its backup are unreadable',
          backupError,
        );
      }
    }
  }

  Future<void> save(List<StickerPack> packs) {
    final snapshot = packs.map((pack) => pack.toJson()).toList();
    final write = _pendingWrite.then((_) => _saveNow(snapshot));
    _pendingWrite = write.catchError((_) {});
    return write;
  }

  Future<void> _saveNow(List<Map<String, Object?>> packs) async {
    await root.create(recursive: true);
    final document = <String, Object?>{
      'schemaVersion': schemaVersion,
      'packs': packs,
    };

    try {
      if (await temporaryFile.exists()) await temporaryFile.delete();
      await temporaryFile.writeAsString(jsonEncode(document), flush: true);

      if (await backupFile.exists()) await backupFile.delete();
      if (await metadataFile.exists()) {
        await metadataFile.rename(backupFile.path);
      }

      try {
        await temporaryFile.rename(metadataFile.path);
      } catch (_) {
        if (!await metadataFile.exists() && await backupFile.exists()) {
          await backupFile.rename(metadataFile.path);
        }
        rethrow;
      }
    } catch (error) {
      throw PackRepositoryException('Could not save pack metadata', error);
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  Future<List<StickerPack>> _read(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    final Object? rawPacks;
    if (decoded is List) {
      rawPacks = decoded; // Legacy, pre-schema format.
    } else if (decoded is Map<String, dynamic>) {
      final version = decoded['schemaVersion'];
      if (version is! int || version > schemaVersion || version < 1) {
        throw const FormatException('Unsupported pack metadata schema');
      }
      rawPacks = decoded['packs'];
    } else {
      throw const FormatException('Pack metadata must be an object or list');
    }

    if (rawPacks is! List) {
      throw const FormatException('Pack metadata does not contain a pack list');
    }
    return rawPacks.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Pack entry must be an object');
      }
      return StickerPack.fromJson(Map<String, dynamic>.from(entry));
    }).toList(growable: true);
  }

  Future<void> _replaceFile(
    File source,
    File destination, {
    required bool preserveSource,
  }) async {
    final recovery = File('${destination.path}.recovery');
    if (await recovery.exists()) await recovery.delete();
    await source.copy(recovery.path);
    if (await destination.exists()) await destination.delete();
    await recovery.rename(destination.path);
    if (!preserveSource && await source.exists()) await source.delete();
  }
}
