import 'dart:convert';

enum StreamFormat { hls, dash, flv, transportStream, file, unknown }

/// A media URL and its request context. Never rebuild the URL's signed query.
class PlaybackSource {
  PlaybackSource._(this.url, Map<String, String> headers, this.format)
    : headers = Map.unmodifiable(headers);

  final String url;
  final Map<String, String> headers;
  final StreamFormat format;

  factory PlaybackSource.parse(
    String input, {
    Map<String, String> attributes = const {},
    Map<String, String> headers = const {},
  }) {
    final parts = input.trim().split('|');
    final uri = Uri.parse(parts.first);
    final result = <String, String>{};
    void put(String key, String value) {
      key = key.trim();
      value = value.trim();
      if (!RegExp(r"^[!#$%&'*+.^_`~0-9A-Za-z-]+$").hasMatch(key) ||
          value.isEmpty ||
          value.contains(RegExp(r'[\r\n]'))) {
        return;
      }
      result.removeWhere((k, _) => k.toLowerCase() == key.toLowerCase());
      result[key] = value;
    }

    const aliases = {
      'http-user-agent': 'User-Agent',
      'user-agent': 'User-Agent',
      'http-referrer': 'Referer',
      'http-referer': 'Referer',
      'referer': 'Referer',
      'referrer': 'Referer',
      'http-origin': 'Origin',
      'origin': 'Origin',
      'http-cookie': 'Cookie',
      'cookie': 'Cookie',
      'authorization': 'Authorization',
    };
    for (final entry in attributes.entries) {
      final name = aliases[entry.key.toLowerCase()];
      if (name != null) put(name, entry.value);
    }
    for (final suffix in parts.skip(1)) {
      for (final entry in Uri.splitQueryString(suffix).entries) {
        put(aliases[entry.key.toLowerCase()] ?? entry.key, entry.value);
      }
    }
    for (final entry in headers.entries) {
      put(entry.key, entry.value);
    }
    // Explicit headers win. Do not send Huya defaults to unrelated hosts.
    if (uri.host == 'huya.com' ||
        uri.host.endsWith('.huya.com') ||
        uri.host == 'msstatic.com' ||
        uri.host.endsWith('.msstatic.com')) {
      if (!result.keys.any((k) => k.toLowerCase() == 'referer')) {
        put('Referer', 'https://www.huya.com/');
      }
      if (!result.keys.any((k) => k.toLowerCase() == 'user-agent')) {
        put('User-Agent', 'Mozilla/5.0');
      }
    }
    // Some redirect/CDN endpoints reject Lavf, ExoPlayer or Dart identifiers.
    // Keep one browser-compatible default across probing and every backend.
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        !result.keys.any((k) => k.toLowerCase() == 'user-agent')) {
      put('User-Agent', 'Mozilla/5.0');
    }
    final hint = uri.fragment.toLowerCase();
    final path = uri.path.toLowerCase();
    final format = path.endsWith('.m3u8') || hint == '.m3u8'
        ? StreamFormat.hls
        : path.endsWith('.mpd') || hint == '.mpd'
        ? StreamFormat.dash
        : path.endsWith('.flv') ||
              hint == '.flv' ||
              uri.scheme == 'rtmp' ||
              uri.scheme == 'rtmps'
        ? StreamFormat.flv
        : path.endsWith('.ts') || uri.scheme == 'udp' || uri.scheme == 'rtp'
        ? StreamFormat.transportStream
        : RegExp(r'\.(mp4|m4v|mov|mkv|webm|avi|mp3|m4a)$').hasMatch(path)
        ? StreamFormat.file
        : StreamFormat.unknown;
    // IPTV fragments often contain format hints, not part of the media URL.
    final url = parts.first.split('#').first;
    return PlaybackSource._(url, result, format);
  }

  /// Keeps authentication context when selecting an HLS rendition.
  PlaybackSource withUrl(String url) =>
      PlaybackSource.parse(url, headers: headers);
}

/// m3u_parser_nullsafe treats a comment immediately after EXTINF as the URL.
/// Fold VLC/Kodi headers into URL options before handing the text to it.
String prepareM3uForPlayback(String text) {
  final output = <String>[];
  final headers = <String, String>{};
  var awaitingUrl = false;
  for (final raw in text.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.startsWith('#EXTINF:')) {
      headers.clear();
      awaitingUrl = true;
      output.add(line);
    } else if (awaitingUrl && line.startsWith('#EXTVLCOPT:')) {
      final option = line.substring('#EXTVLCOPT:'.length);
      final equals = option.indexOf('=');
      if (equals > 0 &&
          const [
            'http-user-agent',
            'http-referrer',
            'http-referer',
            'http-origin',
            'http-cookie',
          ].contains(option.substring(0, equals))) {
        headers[option.substring(0, equals)] = option.substring(equals + 1);
      }
    } else if (awaitingUrl && line.startsWith('#EXTHTTP:')) {
      try {
        final values = jsonDecode(line.substring('#EXTHTTP:'.length));
        if (values is Map) {
          for (final entry in values.entries) {
            if (entry.value is String) {
              headers[entry.key.toString()] = entry.value;
            }
          }
        }
      } on FormatException {
        /* Ignore malformed optional metadata. */
      }
    } else if (awaitingUrl && line.startsWith('#KODIPROP:')) {
      final equals = line.indexOf('=');
      if (equals > 0 &&
          (line.substring(0, equals).endsWith('.stream_headers') ||
              line.substring(0, equals).endsWith('.manifest_headers'))) {
        headers.addAll(Uri.splitQueryString(line.substring(equals + 1)));
      }
    } else if (awaitingUrl && line.isNotEmpty && !line.startsWith('#')) {
      final options = Uri(queryParameters: headers).query;
      final pipe = line.indexOf('|');
      output.add(
        options.isEmpty
            ? line
            : pipe < 0
            ? '$line|$options'
            : '${line.substring(0, pipe)}|$options&${line.substring(pipe + 1)}',
      );
      awaitingUrl = false;
      headers.clear();
    } else if (!awaitingUrl && line.isNotEmpty) {
      output.add(line);
    }
  }
  return output.join('\n');
}
