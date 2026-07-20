import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AppDiagnostics {
  static const _maxLogBytes = 512 * 1024;
  static File? _logFile;
  static Future<void> _pendingWrite = Future.value();

  static File? get logFile => _logFile;

  static Future<void> initialize(Directory directory) async {
    await directory.create(recursive: true);
    _logFile =
        File('${directory.path}${Platform.pathSeparator}diagnostics.log');
    await _rotateIfNeeded();
  }

  static void installGlobalHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
      record(
        details.exception,
        details.stack ?? StackTrace.current,
        context: details.context?.toDescription() ?? 'Flutter framework',
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, context: 'Uncaught platform error');
      return true;
    };
  }

  static void record(
    Object error,
    StackTrace stack, {
    required String context,
  }) {
    debugPrint('$context: $error\n$stack');
    final file = _logFile;
    if (file == null) return;
    final entry = '${DateTime.now().toUtc().toIso8601String()} '
        '[$context] $error\n$stack\n\n';
    _pendingWrite = _pendingWrite.then((_) async {
      await _rotateIfNeeded(additionalBytes: entry.length);
      await file.writeAsString(entry, mode: FileMode.append, flush: true);
    }).catchError((Object writeError) {
      debugPrint('Could not write diagnostics log: $writeError');
    });
  }

  static Future<void> flush() => _pendingWrite;

  static Future<void> _rotateIfNeeded({int additionalBytes = 0}) async {
    final file = _logFile;
    if (file == null || !await file.exists()) return;
    if (await file.length() + additionalBytes <= _maxLogBytes) return;

    final previous = File('${file.path}.1');
    if (await previous.exists()) await previous.delete();
    await file.rename(previous.path);
  }
}
