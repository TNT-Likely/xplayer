import 'package:flutter_test/flutter_test.dart';
import 'package:m3u_parser_nullsafe/m3u_parser_nullsafe.dart';
import 'dart:convert';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  test('separates headers without changing signed URL bytes', () {
    const url = 'https://cdn.test/live.flv?sign=a%2Bb%2Fc&token=x+y&token=z';
    final source = PlaybackSource.parse(
      '$url|User-Agent=Test%20Player&Referer=https%3A%2F%2Ftest%2F',
    );
    expect(source.url, url);
    expect(source.headers, {
      'User-Agent': 'Test Player',
      'Referer': 'https://test/',
    });
    expect(source.format, StreamFormat.flv);
  });
  test('header precedence is case insensitive and rejects line injection', () {
    final source = PlaybackSource.parse(
      'http://test/live|user-agent=Inline',
      attributes: {'http-user-agent': 'Attribute'},
      headers: {
        'User-Agent': 'Override',
        'Bad Header': 'value',
        'Cookie': 'a\r\nb',
      },
    );
    expect(source.headers, {'User-Agent': 'Override'});
  });
  test('format hints and query strings cannot corrupt routing', () {
    expect(
      PlaybackSource.parse('http://test/play?id=1#.m3u8').format,
      StreamFormat.hls,
    );
    expect(
      PlaybackSource.parse('http://test/play?id=1#.m3u8').url,
      'http://test/play?id=1',
    );
    expect(
      PlaybackSource.parse('http://test/movie.mp4?next=.m3u8').format,
      StreamFormat.file,
    );
  });
  test('Huya defaults respect explicit headers and host boundaries', () {
    expect(
      PlaybackSource.parse('https://cdn.huya.com/live.flv').headers['Referer'],
      'https://www.huya.com/',
    );
    expect(
      PlaybackSource.parse('https://huya.com.fake.test/live.flv').headers,
      {'User-Agent': 'Mozilla/5.0'},
    );
    expect(
      PlaybackSource.parse(
        'https://cdn.huya.com/live.flv|Referer=custom',
      ).headers['Referer'],
      'custom',
    );
  });
  test('rendition selection keeps headers', () {
    final master = PlaybackSource.parse(
      'http://test/master.m3u8|Cookie=session%3Da',
    );
    expect(master.withUrl('http://test/720.m3u8').headers, master.headers);
  });
  test('source cache and sync retain headers containing commas and colons', () {
    final source = Source(
      title: 'Live',
      link: 'http://test/live.flv',
      groupTitle: '',
      duration: -1,
      attributes: {
        'http-user-agent': 'Player, v2: TV',
        'http-cookie': 'a=b, c=d',
      },
    );
    final restored = Source.fromJson(jsonDecode(jsonEncode(source.toJson())));
    expect(restored.attributes, source.attributes);
    final legacy = Source.fromJson({
      ...source.toJson(),
      'attributes': 'http-referrer: https://test/: live',
      'duration': '-1',
    });
    expect(legacy.attributes['http-referrer'], 'https://test/: live');
    expect(legacy.duration, -1);
  });
  test(
    'EXTHTTP supports JSON headers and skips malformed optional metadata',
    () {
      final text = prepareM3uForPlayback('''#EXTM3U
#EXTINF:-1,Live
#EXTHTTP:{"Cookie":"a=b, c=d","User-Agent":"TV Player"}
http://test/live.flv
#EXTINF:-1,Other
#EXTHTTP:broken
http://test/other.flv
''');
      final items = M3uList.load(text).items;
      expect(PlaybackSource.parse(items.first.link).headers, {
        'Cookie': 'a=b, c=d',
        'User-Agent': 'TV Player',
      });
      expect(items.last.link, 'http://test/other.flv');
    },
  );
  test(
    'VLC/Kodi directives produce playable URLs rather than comment URLs',
    () {
      const text = '''\uFEFF#EXTM3U x-tvg-url="http://test/epg.xml"
#EXTINF:-1 tvg-id="one",One
#EXTVLCOPT:http-user-agent=VLC Player
#EXTVLCOPT:http-referrer=https://site.test/
#EXTVLCOPT:network-caching=1000
#KODIPROP:inputstream.adaptive.stream_headers=Cookie=session%3Da
# A comment between metadata and URL
http://test/one.flv|User-Agent=Explicit
#EXTINF:-1 tvg-id="two",Two
http://test/two.m3u8
''';
      final playlist = M3uList.load(prepareM3uForPlayback(text));
      expect(playlist.items.length, 2);
      expect(playlist.header!.attributes['x-tvg-url'], 'http://test/epg.xml');
      final first = PlaybackSource.parse(playlist.items.first.link);
      expect(first.url, 'http://test/one.flv');
      expect(first.headers, {
        'User-Agent': 'Explicit',
        'Referer': 'https://site.test/',
        'Cookie': 'session=a',
      });
      expect(PlaybackSource.parse(playlist.items.last.link).headers, {
        'User-Agent': 'Mozilla/5.0',
      });
    },
  );
}
