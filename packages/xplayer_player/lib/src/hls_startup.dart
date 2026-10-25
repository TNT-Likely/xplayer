import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'playback_source.dart';

/// Avoid probing/downloading every muxed HLS rendition in libavformat before
/// playback. Masters with external audio, subtitles or shared state stay intact.
/// The platform players retain their own adaptive streaming behavior.
Future<PlaybackSource> prepareHlsStartup(
  PlaybackSource source, {
  bool preferLowerBandwidth = false,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final uri = Uri.parse(source.url);
  if (source.format != StreamFormat.hls ||
      !const ['http', 'https'].contains(uri.scheme)) {
    return source;
  }
  final client = HttpClient()..connectionTimeout = timeout;
  client.userAgent = source.headers.entries
      .where((e) => e.key.toLowerCase() == 'user-agent')
      .firstOrNull
      ?.value;
  Future<PlaybackSource> resolve() async {
    final request = await client.getUrl(uri);
    source.headers.forEach(request.headers.set);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return source;
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 256 * 1024) return source;
    }
    final text = utf8.decode(bytes);
    if (!text.trimLeft().startsWith('#EXTM3U') ||
        !text.contains('#EXT-X-STREAM-INF:') ||
        RegExp(
          r'^#EXT-X-(MEDIA|SESSION-KEY|DEFINE):',
          multiLine: true,
        ).hasMatch(text)) {
      return source;
    }
    var base = uri;
    for (final redirect in response.redirects) {
      base = base.resolveUri(redirect.location);
    }
    final choices = <({String url, int bandwidth})>[];
    String? attributes;
    for (final line in const LineSplitter().convert(text)) {
      final value = line.trim();
      if (value.startsWith('#EXT-X-STREAM-INF:')) {
        attributes = value.substring('#EXT-X-STREAM-INF:'.length);
        // Selecting the media URL would lose rendition groups declared in the
        // master, including audio-only fallback and accessibility tracks.
        if (RegExp(
          r'(?:^|,)\s*(AUDIO|VIDEO|SUBTITLES|CLOSED-CAPTIONS)=',
        ).hasMatch(attributes)) {
          return source;
        }
      } else if (value.isNotEmpty &&
          !value.startsWith('#') &&
          attributes != null) {
        final bandwidth = int.tryParse(
          RegExp(
                r'(?:^|,)\s*BANDWIDTH=(\d+)',
              ).firstMatch(attributes)?.group(1) ??
              '',
        );
        final target = base.resolve(value);
        if (bandwidth == null ||
            bandwidth <= 0 ||
            !const ['http', 'https'].contains(target.scheme)) {
          return source;
        }
        choices.add((url: target.toString(), bandwidth: bandwidth));
        attributes = null;
      }
    }
    if (choices.isEmpty || attributes != null) return source;
    choices.sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
    return source.withUrl(
      (preferLowerBandwidth ? choices.first : choices.last).url,
    );
  }

  try {
    return await resolve().timeout(timeout);
  } catch (_) {
    // A metadata probe never prevents the native stack trying the original URL.
    return source;
  } finally {
    client.close(force: true);
  }
}
