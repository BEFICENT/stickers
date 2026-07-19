import 'dart:async';

import 'package:flutter/services.dart';

import 'common.dart';

class AnimatedEncodeException implements Exception {
  final String message;

  const AnimatedEncodeException(this.message);

  @override
  String toString() => message;
}

class OverlayAndEncodeService {
  static const _methodChannel = MethodChannel('de.loicezt.stickers/methods');
  static const _eventChannel =
      EventChannel('de.loicezt.stickers/progress_encode');
  static const _timeout = Duration(minutes: 5);
  static var _requestSequence = 0;
  static var _running = false;

  Future<void> encodeVideo({
    required String videoFile,
    required String overlayFile,
    required String outputFile,
    required WebPConfig config,
    required int fps,
    void Function(Progress progress)? onProgress,
  }) {
    return _encode(
      method: 'startOverlay',
      arguments: {
        'videoFile': videoFile,
        'overlayFile': overlayFile,
        'outputFile': outputFile,
        'fps': fps,
        'config': config.toMap(),
      },
      onProgress: onProgress,
    );
  }

  Future<void> encodeGif({
    required String gifFile,
    required String overlayFile,
    required String outputFile,
    required Duration start,
    required Duration end,
    required WebPConfig config,
    required int fps,
    void Function(Progress progress)? onProgress,
  }) {
    return _encode(
      method: 'startGifOverlay',
      arguments: {
        'gifFile': gifFile,
        'overlayFile': overlayFile,
        'outputFile': outputFile,
        'startMs': start.inMilliseconds,
        'endMs': end.inMilliseconds,
        'fps': fps,
        'config': config.toMap(),
      },
      onProgress: onProgress,
    );
  }

  Future<void> _encode({
    required String method,
    required Map<String, Object?> arguments,
    void Function(Progress progress)? onProgress,
  }) async {
    if (_running) {
      throw const AnimatedEncodeException(
          'Another animated export is running.');
    }
    _running = true;
    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}_${_requestSequence++}';
    final completion = Completer<void>();
    late final StreamSubscription<Object?> subscription;
    subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is! Map || data['requestId'] != requestId) return;
        final progress = _parseProgress(data);
        onProgress?.call(progress);
        if (progress.status == Status.success && !completion.isCompleted) {
          completion.complete();
        } else if (progress.status == Status.failed &&
            !completion.isCompleted) {
          completion.completeError(
            const AnimatedEncodeException('Animated WebP export failed.'),
          );
        } else if (progress.status == Status.cancelled &&
            !completion.isCompleted) {
          completion.completeError(
            const AnimatedEncodeException(
                'Animated WebP export was cancelled.'),
          );
        }
      },
      onError: (Object error) {
        if (!completion.isCompleted) completion.completeError(error);
      },
    );

    try {
      await _methodChannel.invokeMethod<void>(method, {
        ...arguments,
        'requestId': requestId,
      });
      await completion.future.timeout(
        _timeout,
        onTimeout: () => throw const AnimatedEncodeException(
          'Animated WebP export timed out.',
        ),
      );
    } on PlatformException catch (error) {
      throw AnimatedEncodeException(
        error.message ?? 'Could not start animated WebP export.',
      );
    } finally {
      await subscription.cancel();
      _running = false;
    }
  }

  Progress _parseProgress(Map<dynamic, dynamic> data) {
    final statusName = data['status'] as String?;
    return Progress(
      status: Status.values.firstWhere(
        (status) => status.name.toUpperCase() == statusName,
        orElse: () => Status.idle,
      ),
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      currentFrame: (data['currentFrame'] as num?)?.toInt() ?? 0,
      totalFrames: (data['totalFrames'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> cancel() => _methodChannel.invokeMethod<void>('cancelOverlay');
}
