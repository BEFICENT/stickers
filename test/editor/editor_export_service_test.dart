import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/editor/editor_export_service.dart';
import 'package:stickers/src/editor/editor_layer.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';

void main() {
  test('rejects export before the editor scale is initialized', () async {
    final service = EditorExportService();

    await expectLater(
      service.export(EditorExportRequest(
        source: File('unused.webp'),
        mediaType: MediaType.picture,
        layers: const <EditorLayer>[],
        scaleFactor: 0,
      )),
      throwsA(
        isA<EditorExportException>().having(
          (error) => error.failure,
          'failure',
          EditorExportFailure.editorNotReady,
        ),
      ),
    );
  });

  test('rejects GIF trim ranges at or above ten seconds', () async {
    final service = EditorExportService();

    await expectLater(
      service.export(EditorExportRequest(
        source: File('unused.gif'),
        mediaType: MediaType.gif,
        layers: const <EditorLayer>[],
        scaleFactor: 1,
        trimEnd: const Duration(seconds: 10),
      )),
      throwsA(
        isA<EditorExportException>().having(
          (error) => error.failure,
          'failure',
          EditorExportFailure.durationTooLong,
        ),
      ),
    );
  });

  test('defensively rejects long video sources before encoding', () async {
    final service = EditorExportService();

    await expectLater(
      service.export(EditorExportRequest(
        source: File('unused.mp4'),
        mediaType: MediaType.video,
        layers: const <EditorLayer>[],
        scaleFactor: 1,
        videoDuration: const Duration(seconds: 10),
      )),
      throwsA(
        isA<EditorExportException>().having(
          (error) => error.failure,
          'failure',
          EditorExportFailure.durationTooLong,
        ),
      ),
    );
  });
}
