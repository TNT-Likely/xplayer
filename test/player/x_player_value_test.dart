import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:xplayer/services/player/x_player_backend.dart';

void main() {
  test('default value is uninitialized & idle', () {
    const v = XPlayerValue();
    expect(v.isInitialized, false);
    expect(v.isPlaying, false);
    expect(v.isBuffering, false);
    expect(v.hasError, false);
    expect(v.size, Size.zero);
    expect(v.aspectRatio, 1.0);
  });
  test('aspectRatio from size', () {
    const v = XPlayerValue(isInitialized: true, size: Size(1920, 1080));
    expect(v.aspectRatio, closeTo(1920 / 1080, 0.0001));
  });
  test('copyWith overrides only given fields', () {
    const v = XPlayerValue(isPlaying: false, isBuffering: true);
    final v2 = v.copyWith(isPlaying: true);
    expect(v2.isPlaying, true);
    expect(v2.isBuffering, true);
  });
}
