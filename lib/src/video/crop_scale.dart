import 'dart:async';

import 'package:flutter/services.dart';

import 'common.dart';

class CropAndScaleService {
  static const _methodChannel = MethodChannel('de.loicezt.stickers/methods');
  static const _eventChannel =
      EventChannel('de.loicezt.stickers/progress_trim');
  static var _requestSequence = 0;

  final _progressController = StreamController<Progress>.broadcast();
  bool _running = false;

  Stream<Progress> get progressStream => _progressController.stream;

  Future<void> trim({
    required String inputFile,
    required String outputFile,
    required Duration start,
    required Duration end,
  }) async {
    if (_running) throw StateError('Another video trim is running.');
    _running = true;
    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}_${_requestSequence++}';
    final completion = Completer<void>();
    late final StreamSubscription<Object?> subscription;
    subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is! Map || data['requestId'] != requestId) return;
        final progress = _parseProgress(data);
        _progressController.add(progress);
        if (progress.status == Status.success && !completion.isCompleted) {
          completion.complete();
        } else if ((progress.status == Status.failed ||
                progress.status == Status.cancelled) &&
            !completion.isCompleted) {
          completion.completeError(StateError('Video trimming failed.'));
        }
      },
      onError: (Object error) {
        if (!completion.isCompleted) completion.completeError(error);
      },
    );

    try {
      await _methodChannel.invokeMethod<void>('startTrim', {
        'requestId': requestId,
        'inputFile': inputFile,
        'outputFile': outputFile,
        'startTimeUs': start.inMicroseconds,
        'endTimeUs': end.inMicroseconds,
      });
      await completion.future.timeout(const Duration(minutes: 5));
    } finally {
      await subscription.cancel();
      _running = false;
    }
  }

  Progress _parseProgress(Map<dynamic, dynamic> data) => Progress(
        status: Status.values.firstWhere(
          (status) => status.name.toUpperCase() == data['status'],
          orElse: () => Status.idle,
        ),
        progress: (data['progress'] as num?)?.toDouble() ?? 0,
        currentFrame: (data['currentFrame'] as num?)?.toInt() ?? 0,
        totalFrames: (data['totalFrames'] as num?)?.toInt() ?? 0,
      );

  Future<void> cancel() => _methodChannel.invokeMethod<void>('cancelTrim');

  Future<void> dispose() => _progressController.close();
}
