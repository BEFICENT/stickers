import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/media/animated_trim.dart';

void main() {
  test('accepts the strict app duration cap and rejects longer selections', () {
    expect(isValidAnimatedTrim(maxAnimatedStickerDuration), isTrue);
    expect(
      isValidAnimatedTrim(
        maxAnimatedStickerDuration + const Duration(milliseconds: 1),
      ),
      isFalse,
    );
    expect(isValidAnimatedTrim(Duration.zero), isFalse);
  });

  test('defaults long media to the maximum allowed duration', () {
    final range = initialAnimatedTrimRange(const Duration(seconds: 30));
    expect(range.start, 0);
    expect(range.end, closeTo(0.33, 0.0001));
  });

  test('clamps either moved handle to the maximum span', () {
    const duration = Duration(seconds: 20);
    final movedEnd = clampAnimatedTrimRange(
      const RangeValues(.1, .9),
      duration,
      movedStart: false,
    );
    final movedStart = clampAnimatedTrimRange(
      const RangeValues(.1, .9),
      duration,
      movedStart: true,
    );
    expect(movedEnd.end - movedEnd.start, closeTo(.495, .0001));
    expect(movedStart.end - movedStart.start, closeTo(.495, .0001));
  });
}
