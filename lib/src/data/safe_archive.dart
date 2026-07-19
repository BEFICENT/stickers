import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

const int maxPackArchiveBytes = 100 * 1024 * 1024;
const int maxPackArchiveEntries = 256;
const int maxPackArchiveExpandedBytes = 250 * 1024 * 1024;

class UnsafeArchiveException implements Exception {
  final String message;

  const UnsafeArchiveException(this.message);

  @override
  String toString() => message;
}

Future<void> extractZipSafely(File zipFile, Directory destination) async {
  if (!await zipFile.exists()) {
    throw const UnsafeArchiveException('Archive does not exist.');
  }
  if (await zipFile.length() > maxPackArchiveBytes) {
    throw const UnsafeArchiveException('Archive is too large.');
  }

  final input = InputFileStream(zipFile.path);
  late final Archive archive;
  try {
    archive = ZipDecoder().decodeStream(input);
  } on Object catch (error) {
    await input.close();
    throw UnsafeArchiveException('Archive could not be decoded: $error');
  }

  try {
    if (archive.length > maxPackArchiveEntries) {
      throw const UnsafeArchiveException('Archive contains too many files.');
    }
    var expandedSize = 0;
    for (final entry in archive) {
      final normalized = path.normalize(entry.name.replaceAll('\\', '/'));
      final destinationPath = path.join(destination.path, normalized);
      if (normalized == '.' ||
          path.isAbsolute(normalized) ||
          !path.isWithin(destination.path, destinationPath) ||
          entry.isSymbolicLink) {
        throw UnsafeArchiveException(
          'Archive contains an unsafe path: ${entry.name}',
        );
      }
      expandedSize += entry.size;
      if (expandedSize > maxPackArchiveExpandedBytes) {
        throw const UnsafeArchiveException(
          'Archive expands beyond the size limit.',
        );
      }
    }

    await destination.create(recursive: true);
    await extractArchiveToDisk(archive, destination.path);

    for (final entry in archive.where((entry) => entry.isFile)) {
      final normalized = path.normalize(entry.name.replaceAll('\\', '/'));
      final extracted = File(path.join(destination.path, normalized));
      if (!await extracted.exists() || await extracted.length() != entry.size) {
        throw UnsafeArchiveException(
          'Archive entry could not be extracted: ${entry.name}',
        );
      }
    }
  } finally {
    await archive.clear();
    await input.close();
  }
}
