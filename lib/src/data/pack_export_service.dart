import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:stickers/src/data/sticker_pack.dart';

class PackExportService {
  final Directory outputDirectory;

  const PackExportService({required this.outputDirectory});

  Future<List<File>> createArchives(Iterable<StickerPack> packs) async {
    final selectedPacks = packs.toList(growable: false);
    if (selectedPacks.isEmpty) return const [];

    final sessionDirectory = Directory(path.join(
      outputDirectory.path,
      'export_${DateTime.now().microsecondsSinceEpoch}',
    ));
    await sessionDirectory.create(recursive: true);

    final archives = <File>[];
    try {
      for (var index = 0; index < selectedPacks.length; index++) {
        final pack = selectedPacks[index];
        final suffix = selectedPacks.length == 1 ? '' : '_${index + 1}';
        final archive = File(path.join(
          sessionDirectory.path,
          '${_safeFileName(pack.title)}$suffix.zip',
        ));
        await _createArchive(pack, archive);
        archives.add(archive);
      }
      return archives;
    } catch (_) {
      if (await sessionDirectory.exists()) {
        await sessionDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _createArchive(StickerPack pack, File output) async {
    final sources = <({File file, String archiveName})>[];
    final exportData = pack.toJson();
    final stickerData = exportData['stickers']! as List;

    for (var index = 0; index < pack.stickers.length; index++) {
      final source = File(pack.stickers[index].source);
      await _requireFile(source);
      final archiveName = '$index.webp';
      (stickerData[index] as Map<String, dynamic>)['source'] = archiveName;
      sources.add((file: source, archiveName: archiveName));
    }

    if (pack.trayIcon != null) {
      final source = File(pack.trayIcon!);
      await _requireFile(source);
      final extension = path.extension(source.path).toLowerCase();
      final archiveName = 'tray${extension.isEmpty ? '.webp' : extension}';
      exportData['trayIcon'] = archiveName;
      sources.add((file: source, archiveName: archiveName));
    }

    final encoder = ZipFileEncoder();
    try {
      encoder.create(output.path);
      encoder.addArchiveFile(
        ArchiveFile.string('pack.json', jsonEncode(exportData)),
      );
      for (final source in sources) {
        await encoder.addFile(source.file, source.archiveName);
      }
      await encoder.close();
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    }
  }

  Future<void> _requireFile(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Sticker pack file is missing', file.path);
    }
  }

  String _safeFileName(String title) {
    final sanitized =
        title.replaceAll(RegExp(r'[^ _\-!&a-zA-Z0-9]'), '_').trim();
    return sanitized.isEmpty ? 'sticker_pack' : sanitized;
  }
}
