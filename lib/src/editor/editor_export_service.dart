import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/editor/editor_layer.dart';
import 'package:stickers/src/fonts_api/fonts_registry.dart';
import 'package:stickers/src/media/animated_export_policy.dart';
import 'package:stickers/src/media/animated_trim.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/video/common.dart';
import 'package:stickers/src/video/overlay_encode.dart';
import 'package:stickers/src/widgets/draw_layer.dart';
import 'package:stickers/src/widgets/text_layer.dart';

enum EditorExportFailure {
  editorNotReady,
  durationTooLong,
  outputTooLarge,
  renderFailed,
}

class EditorExportException implements Exception {
  final EditorExportFailure failure;

  const EditorExportException(this.failure);

  @override
  String toString() => failure.name;
}

class EditorExportRequest {
  final File source;
  final MediaType mediaType;
  final List<EditorLayer> layers;
  final double scaleFactor;
  final Duration trimStart;
  final Duration? trimEnd;
  final Duration? videoDuration;

  const EditorExportRequest({
    required this.source,
    required this.mediaType,
    required this.layers,
    required this.scaleFactor,
    this.trimStart = Duration.zero,
    this.trimEnd,
    this.videoDuration,
  });
}

class EditorExportService {
  final OverlayAndEncodeService animatedEncoder;

  EditorExportService({OverlayAndEncodeService? animatedEncoder})
      : animatedEncoder = animatedEncoder ?? OverlayAndEncodeService();

  Future<Uint8List> export(
    EditorExportRequest request, {
    void Function(int attempt)? onAttempt,
    void Function(Progress progress)? onProgress,
  }) async {
    if (request.scaleFactor <= 0) {
      throw const EditorExportException(EditorExportFailure.editorNotReady);
    }
    final option = _buildOption(request.layers, request.scaleFactor);
    if (request.mediaType == MediaType.picture) {
      final data = await ImageEditor.editFileImage(
        file: request.source,
        imageEditorOption: option,
      );
      if (data == null) {
        throw const EditorExportException(EditorExportFailure.renderFailed);
      }
      return data;
    }
    return _exportAnimated(
      request,
      option,
      onAttempt: onAttempt,
      onProgress: onProgress,
    );
  }

  ImageEditorOption _buildOption(
    List<EditorLayer> layers,
    double scaleFactor,
  ) {
    final option = ImageEditorOption();
    for (final layer in layers) {
      final Option layerOption;
      if (layer is TextLayer) {
        final textOption = AddTextOption();
        final exportTransform = Matrix4.copy(layer.text.transform);
        final transform = exportTransform.storage;
        transform[12] /= scaleFactor;
        transform[13] /= scaleFactor;
        final fontName = layer.text.fontName;
        textOption.addText(EditorText(
          text: layer.text.text,
          transform: exportTransform,
          fontSize: layer.text.fontSize /
              scaleFactor *
              (FontsRegistry.sizeMultiplier(fontName) ?? 1),
          textColor: layer.text.textColor,
          fontName: fontName == 'sans-serif' || fontName == 'monospace'
              ? ''
              : fontName,
          outlineColor: layer.text.outlineColor,
          outlineWidth: layer.text.outlineWidth / scaleFactor,
        ));
        layerOption = textOption;
      } else if (layer is DrawLayer) {
        layerOption = layer.drawOption;
      } else {
        throw const EditorExportException(EditorExportFailure.renderFailed);
      }
      option.addOption(layerOption);
    }
    option.outputFormat = const OutputFormat.webp_lossy();
    return option;
  }

  Future<Uint8List> _exportAnimated(
    EditorExportRequest request,
    ImageEditorOption option, {
    void Function(int attempt)? onAttempt,
    void Function(Progress progress)? onProgress,
  }) async {
    final trimEnd = request.trimEnd ?? maxAnimatedStickerDuration;
    if (request.mediaType == MediaType.gif &&
        !isValidAnimatedTrim(trimEnd - request.trimStart)) {
      throw const EditorExportException(EditorExportFailure.durationTooLong);
    }
    if (request.mediaType == MediaType.video &&
        (request.videoDuration ?? Duration.zero) > maxAnimatedStickerDuration) {
      throw const EditorExportException(EditorExportFailure.durationTooLong);
    }

    final transparent = await rootBundle.load('assets/transparent.webp');
    final overlay = await ImageEditor.editImageAndGetFile(
      image: transparent.buffer.asUint8List(),
      imageEditorOption: option,
    );
    final output = File(
      '$mediaCacheDir/exported_${DateTime.now().microsecondsSinceEpoch}.webp',
    );
    Uint8List? data;
    var settings = const AnimatedExportSettings(quality: 60, fps: 24);
    final stopwatch = Stopwatch()..start();

    try {
      for (var attempt = 0; attempt < animatedExportAttempts; attempt++) {
        onAttempt?.call(attempt);
        final config = WebPConfig(
          lossless: false,
          quality: settings.quality,
          alphaCompression: 1,
          method: 4,
        );
        if (request.mediaType == MediaType.gif) {
          await animatedEncoder.encodeGif(
            gifFile: request.source.path,
            overlayFile: overlay.path,
            outputFile: output.path,
            start: request.trimStart,
            end: trimEnd,
            config: config,
            fps: settings.fps,
            onProgress: onProgress,
          );
        } else {
          await animatedEncoder.encodeVideo(
            videoFile: request.source.path,
            overlayFile: overlay.path,
            outputFile: output.path,
            config: config,
            fps: settings.fps,
            onProgress: onProgress,
          );
        }
        data = await output.readAsBytes();
        debugPrint(
          'Exported animated WebP in ${stopwatch.elapsedMilliseconds}ms '
          '(${(data.lengthInBytes / 1024).toStringAsFixed(1)} KiB)',
        );
        if (animatedOutputFits(data.lengthInBytes)) break;
        settings = settings.afterOversizedResult(data.lengthInBytes);
      }
    } finally {
      if (await output.exists()) await output.delete();
      if (await overlay.exists()) await overlay.delete();
    }

    if (data == null || data.lengthInBytes > maxAnimatedStickerBytes) {
      throw const EditorExportException(EditorExportFailure.outputTooLarge);
    }
    return data;
  }
}
