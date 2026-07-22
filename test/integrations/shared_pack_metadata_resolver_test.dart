import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/integrations/shared_pack_metadata_resolver.dart';

void main() {
  test('extracts the source provider and pack identifier from a tray name', () {
    final source = PlatformSharedPackMetadataResolver.sourceFromTrayFileName(
      'de.loicezt.stickers.stickercontentprovider pack_123.png',
    );

    expect(source?.authority, 'de.loicezt.stickers.stickercontentprovider');
    expect(source?.identifier, 'pack_123');
  });

  test('ignores ordinary tray image names', () {
    expect(
      PlatformSharedPackMetadataResolver.sourceFromTrayFileName('tray.png'),
      isNull,
    );
  });
}
