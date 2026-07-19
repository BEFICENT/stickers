import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stickers/src/constants.dart';

bool isValidAnimatedTrim(Duration duration) =>
    duration > Duration.zero && duration <= maxAnimatedStickerDuration;

RangeValues initialAnimatedTrimRange(Duration sourceDuration) {
  if (sourceDuration <= Duration.zero ||
      sourceDuration <= maxAnimatedStickerDuration) {
    return const RangeValues(0, 1);
  }
  return RangeValues(
    0,
    maxAnimatedStickerDuration.inMilliseconds / sourceDuration.inMilliseconds,
  );
}

RangeValues clampAnimatedTrimRange(
  RangeValues values,
  Duration sourceDuration, {
  required bool movedStart,
}) {
  if (sourceDuration <= Duration.zero) return const RangeValues(0, 1);
  final maxSpan = min(
    1.0,
    maxAnimatedStickerDuration.inMilliseconds / sourceDuration.inMilliseconds,
  );
  var start = values.start.clamp(0.0, 1.0).toDouble();
  var end = values.end.clamp(0.0, 1.0).toDouble();

  if (end - start > maxSpan) {
    if (movedStart) {
      end = min(1.0, start + maxSpan);
    } else {
      start = max(0.0, end - maxSpan);
    }
  }
  if (end <= start) end = min(1.0, start + .001);
  return RangeValues(start, end);
}
