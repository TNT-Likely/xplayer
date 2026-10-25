import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  test('common audio and legacy video files retain on-demand buffering', () {
    for (final extension in [
      'AAC',
      'mp3',
      'flac',
      'm4a',
      'wav',
      'ogg',
      'opus',
      'wma',
      'ac3',
      'eac3',
      'dts',
      'mlp',
      'truehd',
      'asf',
      'wmv',
      'mpeg',
    ]) {
      final source = PlaybackSource.parse(
        'https://origin.test/file.$extension?token=keep%2Fbytes&next=.m3u8',
      );
      expect(source.format, StreamFormat.file, reason: extension);
      expect(source.url, contains('token=keep%2Fbytes'));
    }
  });
  test(
    'HTTP uses browser UA but leaves explicit agents and native protocols alone',
    () {
      expect(
        PlaybackSource.parse('https://origin.test/live').headers['User-Agent'],
        'Mozilla/5.0',
      );
      expect(
        PlaybackSource.parse(
          'http://origin.test/live|User-Agent=Custom',
        ).headers['User-Agent'],
        'Custom',
      );
      expect(PlaybackSource.parse('rtsp://camera/live').headers, isEmpty);
      expect(PlaybackSource.parse('/tmp/movie.mkv').headers, isEmpty);
    },
  );

  test('signed queries are not normalized or re-encoded', () {
    const url = 'https://origin.test/play?key=a%2fb%2Bc&token=x+y&token=z';
    final source = PlaybackSource.parse('$url|Cookie=session%3Da');
    expect(source.url, url);
    expect(source.headers['Cookie'], 'session=a');
    expect(source.headers['User-Agent'], 'Mozilla/5.0');
  });

  test(
    'explicit header precedence is case insensitive and rejects line injection',
    () {
      final source = PlaybackSource.parse(
        'https://origin.test/live|user-agent=Inline',
        attributes: {'http-user-agent': 'Attribute'},
        headers: {
          'USER-AGENT': 'Override',
          'Cookie': 'a\r\nb',
          'Bad Header': 'value',
        },
      );
      expect(source.headers, {'USER-AGENT': 'Override'});
    },
  );

  test('Huya referer is scoped and never overrides explicit values', () {
    expect(
      PlaybackSource.parse('https://cdn.huya.com/live.flv').headers['Referer'],
      'https://www.huya.com/',
    );
    expect(
      PlaybackSource.parse(
        'https://huya.com.fake.test/live.flv',
      ).headers.containsKey('Referer'),
      isFalse,
    );
    expect(
      PlaybackSource.parse(
        'https://cdn.huya.com/live.flv|Referer=custom',
      ).headers['Referer'],
      'custom',
    );
  });

  test(
    'format hints do not corrupt the actual URL or consume query suffixes',
    () {
      final source = PlaybackSource.parse(
        'https://origin.test/play?next=.flv#.m3u8',
      );
      expect(source.url, 'https://origin.test/play?next=.flv');
      expect(source.format, StreamFormat.hls);
      expect(
        PlaybackSource.parse('https://origin.test/movie.mp4?next=.m3u8').format,
        StreamFormat.file,
      );
    },
  );

  test('M3U comments and optional headers cannot become channel URLs', () {
    final prepared = prepareM3uForPlayback('''#EXTM3U
#EXTINF:-1,Live
#EXTVLCOPT:http-referrer=https://origin.test/
#EXTHTTP:{"Cookie":"a=b, c=d"}
#KODIPROP:inputstream.adaptive.stream_headers=User-Agent=Custom
# comment
http://cdn.test/live.flv
#EXTINF:-1,Other
#EXTHTTP:invalid
http://cdn.test/other.m3u8
''');
    final links = prepared
        .split('\n')
        .where((v) => v.startsWith('http'))
        .toList();
    expect(links.length, 2);
    final source = PlaybackSource.parse(links.first);
    expect(source.headers, {
      'Referer': 'https://origin.test/',
      'Cookie': 'a=b, c=d',
      'User-Agent': 'Custom',
    });
    expect(PlaybackSource.parse(links.last).headers, {
      'User-Agent': 'Mozilla/5.0',
    });
  });
}
