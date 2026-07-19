import 'dart:math';

import 'package:stickers/src/data/pack_validator.dart';

const int animatedExportAttempts = 3;
const int reduceFpsThresholdBytes = 550 * 1024;

class AnimatedExportSettings {
  final double quality;
  final int fps;

  const AnimatedExportSettings({required this.quality, required this.fps});

  AnimatedExportSettings afterOversizedResult(int outputBytes) {
    final nextFps = outputBytes > reduceFpsThresholdBytes
        ? max(1, (fps / outputBytes * reduceFpsThresholdBytes).round())
        : fps;
    return AnimatedExportSettings(quality: quality - 20, fps: nextFps);
  }
}

bool animatedOutputFits(int bytes) => bytes <= maxAnimatedStickerBytes;
