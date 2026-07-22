import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const int whatsappProviderSchemaVersion = 1;

String whatsappImageDataVersion(String packVersion) {
  final version = int.tryParse(packVersion);
  if (version == null) return packVersion;
  return '${version + whatsappProviderSchemaVersion}';
}

class WhatsappProviderStorage {
  final Directory directory;
  final File configFile;
  bool _sessionPrepared = false;

  WhatsappProviderStorage({
    required this.directory,
    required this.configFile,
  });

  Future<void> prepareSession() async {
    if (_sessionPrepared) return;

    await directory.create(recursive: true);
    if (await configFile.exists()) await configFile.delete();
    _sessionPrepared = true;
  }

  File trayFileFor(String packId) {
    final encodedId = base64Url.encode(utf8.encode(packId)).replaceAll('=', '');
    return File(path.join(directory.path, 'tray_$encodedId.png'));
  }
}
