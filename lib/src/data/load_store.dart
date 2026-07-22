import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/data/pack_export_service.dart';
import 'package:stickers/src/data/pack_service.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/data/pack_repository.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/data/safe_archive.dart';
import 'package:stickers/src/globals.dart';
import 'package:stickers/src/integrations/shared_pack_metadata_resolver.dart';
import 'package:stickers/src/media/webp_info.dart';

PackRepository? _packRepository;
PackService? _packService;

PackRepository get packRepository =>
    _packRepository ??= PackRepository(Directory(packsDir));

void configurePackRepository(PackRepository repository) {
  _packRepository = repository;
  _packService = null;
}

PackService get packService => _packService ??= PackService(
      store: packs,
      repository: packRepository,
      root: Directory(packsDir),
    );

class PackImportResult {
  final List<StickerPack> packs;
  final List<StickerPack> packsMissingMetadata;

  const PackImportResult({
    required this.packs,
    this.packsMissingMetadata = const [],
  });
}

Future<void> savePacks(List<StickerPack> packs) async {
  await packRepository.save(packs);
}

Future<void> exportPack(StickerPack pack) => exportPacks([pack]);

Future<void> exportPacks(Iterable<StickerPack> selectedPacks) async {
  final archives = await PackExportService(
    outputDirectory: Directory(exportCacheDir),
  ).createArchives(selectedPacks);
  if (archives.isEmpty) return;
  await SharePlus.instance.share(
    ShareParams(
      files: archives.map((archive) => XFile(archive.path)).toList(),
    ),
  );
}

Future<PackImportResult> importPack(
  File f, {
  SharedPackMetadataResolver metadataResolver =
      const PlatformSharedPackMetadataResolver(),
}) async {
  final stopwatch = Stopwatch()..start();
  final unzipDir = Directory(
    "$mediaCacheDir/pack_${DateTime.timestamp().microsecondsSinceEpoch}",
  );
  try {
    await extractZipSafely(f, unzipDir);
    debugPrint("Unzip t=${stopwatch.elapsedMilliseconds}ms");
    final result = await _parseImportedPacks(f, unzipDir, metadataResolver);
    if (result.packs.isEmpty) {
      throw const FormatException("Archive does not contain a sticker pack");
    }
    debugPrint("Parse t=${stopwatch.elapsedMilliseconds}ms");
    await _installImportedPacks(result.packs, unzipDir, stopwatch);
    return result;
  } finally {
    try {
      if (await unzipDir.exists()) await unzipDir.delete(recursive: true);
    } on Exception catch (e) {
      debugPrint("Failed to delete unzipDir: $e");
    }
    await _deleteIfInsideAppCache(f);
  }
}

Future<PackImportResult> _parseImportedPacks(
  File archive,
  Directory unzipDir,
  SharedPackMetadataResolver metadataResolver,
) async {
  switch (path.extension(archive.path).toLowerCase()) {
    case ".wastickers":
      return _parseWastickersPack(unzipDir, metadataResolver);
    case ".stickify":
      final result = <StickerPack>[];
      await for (final entity in unzipDir.list()) {
        if (entity is! Directory) continue;
        final jsonFile = File("${entity.path}/contents.json");
        if (!await jsonFile.exists()) continue;
        final document = jsonDecode(await jsonFile.readAsString());
        if (document is! Map || document["sticker_packs"] is! List) {
          throw const FormatException("Invalid Stickify pack document");
        }
        for (final rawPack in document["sticker_packs"] as List) {
          final packJson = Map<String, dynamic>.from(rawPack as Map);
          final rawStickers = packJson["stickers"] as List?;
          if (rawStickers == null) {
            throw const FormatException("Stickify pack has no sticker list");
          }
          result.add(
            StickerPack(
              packJson["name"] as String,
              packJson["publisher"] as String,
              "imported",
              rawStickers.map((rawSticker) {
                final sticker = Map<String, dynamic>.from(rawSticker as Map);
                final rawEmojis = sticker["emojis"] as List? ?? const [];
                return Sticker(
                  path.join(entity.path, sticker["image_file"] as String),
                  rawEmojis.isEmpty ? ["❤"] : rawEmojis.cast<String>(),
                );
              }).toList(),
              (packJson["image_data_version"] ?? "1").toString(),
              packJson["animated_sticker_pack"] as bool? ?? false,
              publisherWebsite: packJson["publisher_website"] as String?,
              licenseAgreementWebsite:
                  packJson["license_agreement_website"] as String?,
              privacyPolicyWebsite:
                  packJson["privacy_policy_website"] as String?,
            ),
          );
        }
      }
      return PackImportResult(packs: result);
    default:
      final jsonFile = File("${unzipDir.path}/pack.json");
      if (!await jsonFile.exists()) {
        final result = await _parseWastickersPack(unzipDir, metadataResolver);
        return result.packs.single.stickers.isEmpty
            ? const PackImportResult(packs: [])
            : result;
      }
      final document = jsonDecode(await jsonFile.readAsString());
      if (document is! Map) {
        throw const FormatException("Invalid pack document");
      }
      final pack = StickerPack.fromJson(Map<String, dynamic>.from(document));
      for (final sticker in pack.stickers) {
        sticker.source = path.join(unzipDir.path, sticker.source);
      }
      if (pack.trayIcon != null) {
        pack.trayIcon = path.join(unzipDir.path, pack.trayIcon!);
      }
      return PackImportResult(packs: [pack]);
  }
}

Future<PackImportResult> _parseWastickersPack(
  Directory unzipDir,
  SharedPackMetadataResolver metadataResolver,
) async {
  final contents = await unzipDir.list(followLinks: false).toList();
  final stickerFiles = contents
      .whereType<File>()
      .where((file) => path.extension(file.path).toLowerCase() == ".webp")
      .toList()
    ..sort((left, right) =>
        path.basename(left.path).compareTo(path.basename(right.path)));
  final trayIcon = contents
      .whereType<File>()
      .where((file) => path.extension(file.path).toLowerCase() == ".png")
      .firstOrNull;

  final title = await _readOptionalImportText(
    File(path.join(unzipDir.path, "title.txt")),
  );
  final author = await _readOptionalImportText(
    File(path.join(unzipDir.path, "author.txt")),
  );
  final sourceMetadata = trayIcon == null
      ? null
      : await metadataResolver.resolve(path.basename(trayIcon.path));
  final resolvedTitle = title ?? sourceMetadata?.title;
  final resolvedAuthor = author ?? sourceMetadata?.author;
  final pack = StickerPack(
    resolvedTitle ?? "Imported sticker pack",
    resolvedAuthor ?? "Imported from WhatsApp",
    "imported",
    stickerFiles.map((file) => Sticker(file.path, ["❤"])).toList(),
    "1000",
    false,
    trayIcon: trayIcon?.path,
  );
  return PackImportResult(
    packs: [pack],
    packsMissingMetadata:
        resolvedTitle == null || resolvedAuthor == null ? [pack] : const [],
  );
}

Future<String?> _readOptionalImportText(File file) async {
  if (!await file.exists()) return null;
  final value = (await file.readAsString()).trim();
  return value.isEmpty ? null : value;
}

Future<void> _installImportedPacks(
  List<StickerPack> candidates,
  Directory unzipDir,
  Stopwatch stopwatch,
) async {
  final originalPackCount = packs.length;
  final committedDirectories = <Directory>[];
  final stagingDirectories = <Directory>[];
  await packs.transaction(() async {
    try {
      for (var packIndex = 0; packIndex < candidates.length; packIndex++) {
        final pack = candidates[packIndex];
        pack.id = await _newInternalPackId(packIndex);
        await _validateImportedSources(pack, unzipDir);

        final staging = Directory("$packsDir/.staging_${pack.id}");
        final destination = Directory("$packsDir/${pack.id}");
        stagingDirectories.add(staging);
        await staging.create(recursive: true);

        for (var stickerIndex = 0;
            stickerIndex < pack.stickers.length;
            stickerIndex++) {
          final fileName = "sticker_$stickerIndex.webp";
          await File(pack.stickers[stickerIndex].source)
              .copy(path.join(staging.path, fileName));
          pack.stickers[stickerIndex].source =
              path.join(destination.path, fileName);
        }
        if (pack.trayIcon != null) {
          final extension = path.extension(pack.trayIcon!).toLowerCase();
          final fileName = "tray${extension.isEmpty ? '.webp' : extension}";
          await File(pack.trayIcon!).copy(path.join(staging.path, fileName));
          pack.trayIcon = path.join(destination.path, fileName);
        }

        await staging.rename(destination.path);
        stagingDirectories.remove(staging);
        committedDirectories.add(destination);
        packs.add(pack);
        debugPrint("[${pack.id}] Copy t=${stopwatch.elapsedMilliseconds}ms");
      }
      await savePacks(packs);
    } catch (_) {
      packs.removeRange(originalPackCount, packs.length);
      for (final directory in [
        ...stagingDirectories,
        ...committedDirectories,
      ]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
      rethrow;
    }
  });
}

Future<void> _validateImportedSources(
  StickerPack pack,
  Directory unzipDir,
) async {
  if (pack.stickers.isEmpty || pack.stickers.length > maxPackStickerCount) {
    throw const FormatException("Imported pack has an invalid sticker count");
  }
  bool? animated;
  for (final sticker in pack.stickers) {
    final file = await _requireContainedFile(unzipDir, sticker.source);
    sticker.source = file.path;
    final info = await readWebPInfo(file);
    animated ??= info.animated;
    if (animated != info.animated) {
      throw const FormatException(
        "Imported pack mixes static and animated stickers",
      );
    }
  }
  pack.animated = animated ?? false;
  if (pack.trayIcon != null) {
    pack.trayIcon =
        (await _requireContainedFile(unzipDir, pack.trayIcon!)).path;
  }
  await const PackValidator().validateOrThrow(pack);
}

Future<File> _requireContainedFile(Directory root, String candidate) async {
  final rootPath = path.normalize(root.absolute.path);
  final file = File(path.normalize(File(candidate).absolute.path));
  if (!path.isWithin(rootPath, file.path) || !await file.exists()) {
    throw const FormatException("Pack references a file outside its archive");
  }
  return file;
}

Future<String> _newInternalPackId(int suffix) async {
  final base = "pack_${DateTime.timestamp().microsecondsSinceEpoch}_$suffix";
  var candidate = base;
  var collision = 0;
  while (packs.any((pack) => pack.id == candidate) ||
      await Directory("$packsDir/$candidate").exists()) {
    candidate = "${base}_${++collision}";
  }
  return candidate;
}

Future<List<StickerPack>> getPacks() async {
  final loaded = await packRepository.load();
  await pruneMissingStickerFiles(loaded);
  return loaded;
}

Future<Uint8List> cropSticker(Rect cropRect, Uint8List rawImageData,
    StickerPack pack, int index, double rotation) async {
  final crop = ImageEditorOption();
  Size oldSize = cropRect.size;
  crop.addOption(RotateOption(rotation.toInt()));
  crop.addOption(ClipOption.fromRect(cropRect));
  Size newSize;
  if (oldSize.height > oldSize.width) {
    newSize = Size(oldSize.width * 512 / oldSize.height, 512);
  } else {
    newSize = Size(512, oldSize.height * 512 / oldSize.width);
  }
  crop.addOption(
    ScaleOption(
      newSize.width.toInt(),
      newSize.height.toInt(),
    ),
  );
  crop.outputFormat = const OutputFormat.png();
  final intermediate = (await ImageEditor.editImage(
      image: rawImageData, imageEditorOption: crop))!;

  final option = ImageMergeOption(
    canvasSize: const Size.square(512),
    format: const OutputFormat.webp_lossy(50),
  );

  option.addImage(
    MergeImageConfig(
      image: MemoryImageSource(intermediate),
      position: ImagePosition(
        Offset((512 - newSize.width) / 2, (512 - newSize.height) / 2),
        newSize,
      ),
    ),
  );
  return (await ImageMerger.mergeToMemory(option: option))!;
}

Future<void> addToPack(StickerPack pack, int index, Uint8List data) async {
  await packService.addStickerBytes(pack, index, data);
  await _cleanupMediaCache();
}

Future<void> deleteStickerFromPack(StickerPack pack, int index) async {
  await packService.deleteSticker(pack, index);
}

Future<void> deletePack(StickerPack pack) async {
  await packService.deletePack(pack);
}

Future<void> deletePacks(Iterable<StickerPack> selectedPacks) async {
  await packService.deletePacks(selectedPacks);
}

Future<void> reorderPacks(List<StickerPack> orderedPacks) async {
  await packService.reorderPacks(orderedPacks);
}

Future<void> createPack(StickerPack pack) => packService.createPack(pack);

Future<void> updatePack(StickerPack pack, PackDetails details) =>
    packService.updatePack(pack, details);

Future<void> updateStickerEmojis(
  StickerPack pack,
  int index,
  List<String> emojis,
) =>
    packService.updateStickerEmojis(pack, index, emojis);

Future<void> setPackTray(StickerPack pack, File source) =>
    packService.setTrayFromFile(pack, source);

Future<void> _cleanupMediaCache() async {
  try {
    final dir = Directory(mediaCacheDir);
    if (!await dir.exists()) return;

    final now = DateTime.now();
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > const Duration(minutes: 10)) {
          try {
            await entity.delete();
          } on Exception catch (e) {
            debugPrint("Failed to delete cache file: $e");
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Cache cleanup error: $e");
  }
}

Future<void> _deleteIfInsideAppCache(File file) async {
  final appCacheRoot = Directory(cacheDir).parent.path;
  final appCachePrefix = appCacheRoot.endsWith(Platform.pathSeparator)
      ? appCacheRoot
      : "$appCacheRoot${Platform.pathSeparator}";
  if (!file.path.startsWith(appCachePrefix)) return;

  try {
    await file.delete();
  } on Exception catch (e) {
    debugPrint("Failed to delete app cache file: $e");
  }
}

Future<File> saveTemp(Uint8List data) async {
  File output =
      File("$mediaCacheDir/${DateTime.now().millisecondsSinceEpoch}.tmp.webp");
  await output.writeAsBytes(data, flush: true);
  return output;
}

Future<void> pruneMissingStickerFiles(List<StickerPack> packs) async {
  var changed = false;
  for (final pack in packs) {
    final existingStickers = <Sticker>[];
    for (final sticker in pack.stickers) {
      if (await File(sticker.source).exists()) {
        existingStickers.add(sticker);
      } else {
        changed = true;
        debugPrint(
            "Removing missing sticker file from pack ${pack.id}: ${sticker.source}");
      }
    }
    if (existingStickers.length != pack.stickers.length) {
      pack.stickers
        ..clear()
        ..addAll(existingStickers);
    }
    if (pack.trayIcon != null && !await File(pack.trayIcon!).exists()) {
      debugPrint(
          "Removing missing tray icon from pack ${pack.id}: ${pack.trayIcon}");
      pack.trayIcon = null;
      changed = true;
    }
  }
  if (changed) {
    await savePacks(packs);
  }
}
