import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/player/player_backend_selector.dart';

void main() {
  test('Android + 开 → native', () {
    expect(selectBackendKind(isAndroid: true, nativeEnabled: true),
        PlayerBackendKind.native);
  });
  test('Android + 关 → videoPlayer', () {
    expect(selectBackendKind(isAndroid: true, nativeEnabled: false),
        PlayerBackendKind.videoPlayer);
  });
  test('非 Android 一律 videoPlayer(即便开关开)', () {
    expect(selectBackendKind(isAndroid: false, nativeEnabled: true),
        PlayerBackendKind.videoPlayer);
  });
}
