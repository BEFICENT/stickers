import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/diagnostics/app_diagnostics.dart';

void main() {
  test('records local diagnostic context and stack traces', () async {
    final directory = await Directory.systemTemp.createTemp('diagnostics_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await AppDiagnostics.initialize(directory);

    AppDiagnostics.record(
      StateError('expected failure'),
      StackTrace.current,
      context: 'diagnostics test',
    );
    await AppDiagnostics.flush();

    final contents = await AppDiagnostics.logFile!.readAsString();
    expect(contents, contains('diagnostics test'));
    expect(contents, contains('expected failure'));
  });
}
