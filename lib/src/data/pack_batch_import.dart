import 'dart:io';

import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';

typedef PackImporter = Future<PackImportResult> Function(File file);
typedef PackImportProgress = void Function(int completed, int total);

class PackImportFailure {
  final File file;
  final Exception error;
  final StackTrace stackTrace;

  const PackImportFailure({
    required this.file,
    required this.error,
    required this.stackTrace,
  });
}

class PackBatchImportResult {
  final List<StickerPack> packs;
  final List<StickerPack> packsMissingMetadata;
  final List<PackImportFailure> failures;

  const PackBatchImportResult({
    required this.packs,
    required this.packsMissingMetadata,
    required this.failures,
  });
}

Future<PackBatchImportResult> importPackBatch(
  Iterable<File> sourceFiles, {
  PackImporter? importer,
  PackImportProgress? onProgress,
}) async {
  final files = sourceFiles.toList(growable: false);
  final importedPacks = <StickerPack>[];
  final packsMissingMetadata = <StickerPack>[];
  final failures = <PackImportFailure>[];
  final importOne = importer ?? importPack;

  for (var index = 0; index < files.length; index++) {
    final file = files[index];
    try {
      final result = await importOne(file);
      importedPacks.addAll(result.packs);
      packsMissingMetadata.addAll(result.packsMissingMetadata);
    } on Exception catch (error, stackTrace) {
      failures.add(
        PackImportFailure(
          file: file,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
    onProgress?.call(index + 1, files.length);
  }

  return PackBatchImportResult(
    packs: importedPacks,
    packsMissingMetadata: packsMissingMetadata,
    failures: failures,
  );
}
