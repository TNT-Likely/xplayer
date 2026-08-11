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

  group('positionIsProgressSignal', () {
    test('Android:两种后端底层都是 ExoPlayer,位置可当进展判据', () {
      expect(positionIsProgressSignal(isAndroid: true), isTrue);
    });

    test('非 Android:AVPlayer 对 HLS 直播位置不推进,不能当进展判据', () {
      // iOS 真机实测:直播播放正常但 position 恒为 1ms,若据此判卡死会无限重连。
      expect(positionIsProgressSignal(isAndroid: false), isFalse);
    });
  });
}
