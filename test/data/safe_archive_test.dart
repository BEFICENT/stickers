import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/safe_archive.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('safe_archive_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('extracts files contained by the destination', () async {
    final zip = await _writeZip({'pack/pack.json': '{}'});
    final output = Directory('${temporaryDirectory.path}/output');

    await extractZipSafely(zip, output);

    expect(await File('${output.path}/pack/pack.json').readAsString(), '{}');
  });

  test('rejects parent traversal paths', () async {
    final zip = await _writeZip({'../outside.txt': 'bad'});

    expect(
      () =>
          extractZipSafely(zip, Directory('${temporaryDirectory.path}/output')),
      throwsA(isA<UnsafeArchiveException>()),
    );
  });
}

Future<File> _writeZip(Map<String, String> files) async {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile.string(entry.key, entry.value));
  }
  final directory = await Directory.systemTemp.createTemp('archive_fixture_');
  addTearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });
  final file = File('${directory.path}/input.zip');
  final output = OutputFileStream(file.path);
  ZipEncoder().encode(archive, output: output);
  await output.close();
  return file;
}
