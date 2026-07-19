import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/data/pack_validator.dart';
import 'package:stickers/src/media/animated_export_policy.dart';

void main() {
  test('accepts output exactly at the WhatsApp size limit', () {
    expect(animatedOutputFits(maxAnimatedStickerBytes), isTrue);
    expect(animatedOutputFits(maxAnimatedStickerBytes + 1), isFalse);
  });

  test('reduces quality without dropping fps for a small excess', () {
    const settings = AnimatedExportSettings(quality: 60, fps: 24);
    final next = settings.afterOversizedResult(520 * 1024);
    expect(next.quality, 40);
    expect(next.fps, 24);
  });

  test('drops fps proportionally and never below one', () {
    const settings = AnimatedExportSettings(quality: 20, fps: 2);
    final next = settings.afterOversizedResult(10 * 1024 * 1024);
    expect(next.quality, 0);
    expect(next.fps, 1);
  });
}
