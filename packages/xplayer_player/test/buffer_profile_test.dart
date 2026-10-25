// test/player/buffer_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/xplayer_player.dart';

void main() {
  test('live profile values', () {
    const p = BufferProfile.live;
    expect(p.minMs, 8000);
    expect(p.maxMs, 30000);
    expect(p.playbackMs, 1500);
    expect(p.rebufferMs, 5000);
  });
  test('vod profile values', () {
    const p = BufferProfile.vod;
    expect(p.minMs, 15000);
    expect(p.maxMs, 45000);
    expect(p.playbackMs, 3000);
    expect(p.rebufferMs, 10000);
  });
  test('forUrl: m3u8 → live, else vod', () {
    expect(BufferProfile.forUrl('http://x/live.m3u8'), BufferProfile.live);
    expect(BufferProfile.forUrl('http://x/movie.mp4'), BufferProfile.vod);
  });
  test('id is stable wire string', () {
    expect(BufferProfile.live.id, 'live');
    expect(BufferProfile.vod.id, 'vod');
  });
  test(
    'FLV, MPEG-TS and extensionless channel endpoints use live buffering',
    () {
      for (final url in [
        'http://test/live.flv',
        'http://test/live.ts',
        'http://test/live/huya/123',
        'rtmp://test/live/123',
      ]) {
        expect(BufferProfile.forUrl(url), BufferProfile.live);
      }
    },
  );
}
