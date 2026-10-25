import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  late HttpServer server;
  late String base;
  const master =
      '#EXTM3U\n'
      '#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1920x1080\n'
      'high.m3u8?sign=a%2Bb&token=x+y\n'
      '#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=1920x1080\n'
      'low.m3u8\n';

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
  });
  tearDown(() => server.close(force: true));

  test(
    'selects one muxed rendition and preserves signed query bytes',
    () async {
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        request.response.write(master);
        await request.response.close();
      });
      final source = PlaybackSource.parse('$base/master.m3u8');
      final result = await prepareHlsStartup(source);
      expect(result.url, '$base/high.m3u8?sign=a%2Bb&token=x+y');
      expect(result.headers, source.headers);
      expect(paths, ['/master.m3u8']);
    },
  );

  test(
    'recovery can choose lower bandwidth even at the same resolution',
    () async {
      server.listen((request) async {
        request.response.write(master);
        await request.response.close();
      });
      final result = await prepareHlsStartup(
        PlaybackSource.parse('$base/master.m3u8'),
        preferLowerBandwidth: true,
      );
      expect(result.url, '$base/low.m3u8');
    },
  );

  test(
    'redirect base, browser agent and explicit credentials survive',
    () async {
      final seen = <Map<String, String?>>[];
      server.listen((request) async {
        seen.add({
          'agent': request.headers.value('user-agent'),
          'cookie': request.headers.value('cookie'),
        });
        if (request.uri.path == '/master.m3u8') {
          request.response.statusCode = 302;
          request.response.headers.set('location', '/cdn/master.m3u8');
        } else {
          request.response.write(master);
        }
        await request.response.close();
      });
      final result = await prepareHlsStartup(
        PlaybackSource.parse('$base/master.m3u8|Cookie=session%3Da'),
      );
      expect(result.url, '$base/cdn/high.m3u8?sign=a%2Bb&token=x+y');
      expect(
        seen,
        List.filled(2, {'agent': 'Mozilla/5.0', 'cookie': 'session=a'}),
      );
    },
  );

  for (final sharedState in [
    '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="a",URI="audio.m3u8"\n',
    '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="s",URI="subs.m3u8"\n',
    '#EXT-X-SESSION-KEY:METHOD=AES-128,URI="key"\n',
    '#EXT-X-DEFINE:NAME="token",VALUE="secret"\n',
  ]) {
    test(
      'keeps master shared state: ${sharedState.split(':').first}',
      () async {
        server.listen((request) async {
          request.response.write(master.replaceFirst('\n', '\n$sharedState'));
          await request.response.close();
        });
        final source = PlaybackSource.parse('$base/master.m3u8');
        expect(await prepareHlsStartup(source), same(source));
      },
    );
  }

  test('unresolved rendition groups never lose the external audio', () async {
    server.listen((request) async {
      request.response.write(
        master.replaceFirst('BANDWIDTH=', 'AUDIO="a",BANDWIDTH='),
      );
      await request.response.close();
    });
    final source = PlaybackSource.parse('$base/master.m3u8');
    expect(await prepareHlsStartup(source), same(source));
  });

  for (final payload in [
    '#EXTM3U\n#EXT-X-TARGETDURATION:6\n#EXTINF:6,\nsegment.ts\n',
    '<html>Upstream error</html>',
    '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nfile:///private/file\n',
    '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\n',
    '#EXTM3U\n#EXT-X-STREAM-INF:RESOLUTION=1920x1080\nhigh.m3u8\n',
  ]) {
    test(
      'leaves media/invalid/incomplete manifests to the native stack: $payload',
      () async {
        server.listen((request) async {
          request.response.write(payload);
          await request.response.close();
        });
        final source = PlaybackSource.parse('$base/master.m3u8');
        expect(await prepareHlsStartup(source), same(source));
      },
    );
  }

  test('403 is not treated as a successful manifest rewrite', () async {
    server.listen((request) async {
      request.response.statusCode = 403;
      await request.response.close();
    });
    final source = PlaybackSource.parse('$base/master.m3u8');
    expect(await prepareHlsStartup(source), same(source));
  });

  test(
    'slow metadata has a total deadline and original URL remains usable',
    () async {
      server.listen((request) {});
      final source = PlaybackSource.parse('$base/master.m3u8');
      final watch = Stopwatch()..start();
      expect(
        await prepareHlsStartup(
          source,
          timeout: const Duration(milliseconds: 100),
        ),
        same(source),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    },
  );

  test(
    'oversized metadata is bounded rather than buffered indefinitely',
    () async {
      server.listen((request) async {
        request.response.write('#EXTM3U\n${'x' * (300 * 1024)}');
        await request.response.close();
      });
      final source = PlaybackSource.parse('$base/master.m3u8');
      expect(await prepareHlsStartup(source), same(source));
    },
  );

  test(
    'non-HLS and native protocols do not create metadata requests',
    () async {
      var requests = 0;
      server.listen((request) => requests++);
      for (final url in [
        '$base/live.flv',
        'rtsp://camera/live',
        '/tmp/file.mkv',
      ]) {
        final source = PlaybackSource.parse(url);
        expect(await prepareHlsStartup(source), same(source));
      }
      expect(requests, 0);
    },
  );
}
