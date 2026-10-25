import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  test('desktop occlusion preserves audio; mobile backgrounding pauses', () {
    for (final platform in [
      PlaybackPlatform.macos,
      PlaybackPlatform.windows,
      PlaybackPlatform.linux,
    ]) {
      expect(pausePlaybackWhenHidden(platform), isFalse);
    }
    for (final platform in [PlaybackPlatform.android, PlaybackPlatform.ios]) {
      expect(pausePlaybackWhenHidden(platform), isTrue);
    }
  });
  PlaybackPlan plan(
    PlaybackPlatform platform,
    String url, {
    bool native = true,
  }) => PlaybackPlan(
    platform: platform,
    source: PlaybackSource.parse(url),
    nativeEnabled: native,
  );

  test(
    'Android/TV HLS preserves SurfaceView and can reach a different decoder',
    () {
      final p = plan(PlaybackPlatform.android, 'http://test/live.m3u8');
      expect(p.current, PlayerBackendKind.native);
      expect(p.advance(), isTrue);
      expect(p.current, PlayerBackendKind.videoPlayer);
      expect(p.advance(), isTrue);
      expect(p.current, PlayerBackendKind.mediaKit);
      expect(p.advance(), isTrue);
      expect(p.current, PlayerBackendKind.mediaKitSoftware);
      expect(p.advance(), isFalse);
    },
  );
  test('disabled native engine is never included in fallback', () {
    expect(
      plan(
        PlaybackPlatform.android,
        'http://test/live.m3u8',
        native: false,
      ).engines,
      [
        PlayerBackendKind.videoPlayer,
        PlayerBackendKind.mediaKit,
        PlayerBackendKind.mediaKitSoftware,
      ],
    );
    expect(
      plan(
        PlaybackPlatform.android,
        'http://test/live.flv',
        native: false,
      ).engines,
      [
        PlayerBackendKind.mediaKit,
        PlayerBackendKind.mediaKitSoftware,
        PlayerBackendKind.videoPlayer,
      ],
    );
  });
  for (final platform in PlaybackPlatform.values) {
    for (final url in [
      'http://test/live.flv',
      'http://test/live/huya/123',
      'http://test/live.mpd',
      'rtmp://test/live/room',
      'rtsp://test/camera',
      'http://test/live.ts',
      'http://test/video.mkv',
    ]) {
      test('$platform routes $url through the compatibility decoder first', () {
        expect(plan(platform, url).current, PlayerBackendKind.mediaKit);
      });
    }
  }
  for (final platform in [PlaybackPlatform.ios, PlaybackPlatform.macos]) {
    test(
      '$platform uses full decoders for HLS/MP4 to avoid silently missing audio',
      () {
        for (final url in ['http://test/live.m3u8', 'http://test/movie.mp4']) {
          final p = plan(platform, url);
          expect(p.current, PlayerBackendKind.mediaKit);
          expect(p.advance(), isTrue);
          expect(p.current, PlayerBackendKind.mediaKitSoftware);
          expect(p.advance(), isTrue);
          expect(p.current, PlayerBackendKind.videoPlayer);
          expect(p.advance(), isFalse);
          expect(plan(platform, url).current, PlayerBackendKind.mediaKit);
        }
      },
    );
  }
  test('Linux never falls back to an unregistered video_player plugin', () {
    expect(plan(PlaybackPlatform.linux, 'http://test/live.m3u8').engines, [
      PlayerBackendKind.mediaKit,
      PlayerBackendKind.mediaKitSoftware,
    ]);
  });
  test('audio output failures skip the identical software audio output', () {
    final p = plan(PlaybackPlatform.ios, 'http://test/live.m3u8');
    expect(
      p.advance(
        errorDescription:
            'Bad state: Could not open/initialize audio device -> no sound.',
      ),
      isTrue,
    );
    expect(p.current, PlayerBackendKind.videoPlayer);
    expect(p.advance(), isFalse);
  });
  test('audio output failure still reaches the Android native audio sink', () {
    final p = plan(PlaybackPlatform.android, 'http://test/live.flv');
    expect(
      p.advance(
        errorDescription: 'Could not open/initialize audio device -> no sound.',
      ),
      isTrue,
    );
    expect(p.current, PlayerBackendKind.native);
  });
  test('video decoder failures retain the software recovery path', () {
    final p = plan(PlaybackPlatform.ios, 'http://test/live.m3u8');
    expect(p.advance(errorDescription: 'Video decoder failed'), isTrue);
    expect(p.current, PlayerBackendKind.mediaKitSoftware);
  });
  test('AVPlayer live positions cannot trigger reconnect loops', () {
    expect(positionIsProgressSignal(isAndroid: false), isFalse);
    expect(positionIsProgressSignal(isAndroid: true), isTrue);
  });
  test(
    'compatibility playback on Apple and desktop still detects a frozen clock',
    () {
      final detector = StallDetector();
      final now = DateTime(2026, 10, 25);
      final eligible = positionIsProgressSignal(
        isAndroid: false,
        isCompatibilityBackend: true,
      );
      expect(
        detector.sample(eligible: eligible, position: Duration.zero, now: now),
        isFalse,
      );
      expect(
        detector.sample(
          eligible: eligible,
          position: Duration.zero,
          now: now.add(const Duration(seconds: 9)),
        ),
        isTrue,
      );
    },
  );
}
