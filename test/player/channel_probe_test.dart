import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/channel_test_service.dart';

void main() {
  test(
    'extensionless HLS follows redirected manifests and preserves headers',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      final headers = <String?>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        headers.add(request.headers.value('user-agent'));
        if (request.uri.path == '/play') {
          request.response.statusCode = 302;
          request.response.headers.set('location', '/hls/master');
        } else if (request.uri.path == '/hls/master') {
          request.response.write(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=100\nmedia\n',
          );
        } else if (request.uri.path == '/hls/media') {
          request.response.write('#EXTM3U\n#EXTINF:5,\nsegment.ts\n');
        } else {
          request.response.add(
            List.generate(1024, (i) => i % 188 == 0 ? 0x47 : 0),
          );
        }
        await request.response.close();
      });
      await ChannelTestService().testLatency(
        'http://127.0.0.1:${server.port}/play|User-Agent=TV',
      );
      expect(paths, ['/play', '/hls/master', '/hls/media', '/hls/segment.ts']);
      expect(headers, everyElement('TV'));
    },
  );

  test(
    'HTTP 200 HTML error page is not classified as a working source',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.write('<html>Stream offline</html>');
        await request.response.close();
      });
      await expectLater(
        ChannelTestService().testLatency(
          'http://127.0.0.1:${server.port}/live',
        ),
        throwsException,
      );
    },
  );
}
