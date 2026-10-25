import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  test('redacts signed absolute URLs and relative HTTP request targets', () {
    final result = redactPlaybackLog(
      'Opening https://host/live?token=secret\nGET /segment.ts?auth_key=hidden HTTP/1.1',
    );
    expect(result, isNot(contains('secret')));
    expect(result, isNot(contains('hidden')));
    expect(result, contains('HTTP/1.1'));
  });
  test('redacts credential headers including prefixed native log lines', () {
    final result = redactPlaybackLog(
      '[http] Authorization: Bearer secret\nCookie: session=hidden\nSet-Cookie: new=hidden',
    );
    expect(result, isNot(contains('secret')));
    expect(result, isNot(contains('hidden')));
    expect(result.split('\n'), everyElement('[credentials omitted]'));
  });
  test('keeps actionable HTTP statuses and decoder messages', () {
    expect(
      redactPlaybackLog('https: HTTP error 403 Forbidden'),
      'https: HTTP error 403 Forbidden',
    );
    expect(
      redactPlaybackLog('h264: non-existing PPS 0 referenced'),
      'h264: non-existing PPS 0 referenced',
    );
  });
}
