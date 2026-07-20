import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/media/media_probe.dart';

void main() {
  late Directory temporaryDirectory;
  const probe = MediaProbe();

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('media_probe_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  Future<File> fixture(String name, List<int> bytes) async {
    final file = File('${temporaryDirectory.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  test('detects GIF content without relying on the extension', () async {
    final file = await fixture('shared-media', 'GIF89a'.codeUnits);

    expect((await probe.probe(file)).kind, SourceMediaKind.gif);
  });

  test('detects ISO base media video content', () async {
    final bytes = Uint8List(16)
      ..setRange(4, 8, 'ftyp'.codeUnits)
      ..setRange(8, 12, 'mp42'.codeUnits);
    final file = await fixture('shared-media', bytes);

    expect((await probe.probe(file)).kind, SourceMediaKind.video);
  });

  test('distinguishes HEIC images from ISO base media videos', () async {
    final bytes = Uint8List(16)
      ..setRange(4, 8, 'ftyp'.codeUnits)
      ..setRange(8, 12, 'heic'.codeUnits);
    final file = await fixture('shared-media', bytes);

    expect((await probe.probe(file)).kind, SourceMediaKind.image);
  });

  test('detects ZIP content without relying on the extension', () async {
    final zip = [0x50, 0x4b, 0x03, 0x04];

    expect(
      (await probe.probe(await fixture('pack.wastickers', zip))).kind,
      SourceMediaKind.packArchive,
    );
    expect(
      (await probe.probe(await fixture('unknown.bin', zip))).kind,
      SourceMediaKind.packArchive,
    );
  });

  test('reports unsupported files', () async {
    final file = await fixture('unknown.bin', [1, 2, 3, 4]);

    expect((await probe.probe(file)).kind, SourceMediaKind.unsupported);
  });
}
