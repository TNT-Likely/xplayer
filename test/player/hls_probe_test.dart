import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/utils/hls_probe.dart';

void main() {
  test(
    'HLS probing preserves headers and resolves renditions after redirect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final seenHeaders = <String?>[];
      server.listen((request) async {
        seenHeaders.add(request.headers.value('referer'));
        if (request.uri.path == '/master.m3u8') {
          request.response.statusCode = 302;
          request.response.headers.set('location', '/redirect/master.m3u8');
        } else {
          request.response.write(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720\n720/live.m3u8\n',
          );
        }
        await request.response.close();
      });
      final host = 'http://127.0.0.1:${server.port}';
      final result = await probeHlsVariants(
        '$host/master.m3u8',
        headers: {'Referer': 'https://site.test/'},
      );
      expect(result.error, isNull);
      expect(result.best!.url, '$host/redirect/720/live.m3u8');
      expect(seenHeaders, ['https://site.test/', 'https://site.test/']);
    },
  );
}
