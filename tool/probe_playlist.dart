import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xplayer_player/playback.dart';

/// Network/container diagnostics, not a promise that a device can decode it.
/// Usage: dart run tool/probe_playlist.dart <playlist URL or file> --limit=8
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/probe_playlist.dart <URL/file> [--limit=8]',
    );
    exitCode = 64;
    return;
  }
  final limit =
      args
          .skip(1)
          .where((s) => s.startsWith('--limit='))
          .map((s) => int.parse(s.substring(8)))
          .firstOrNull ??
      8;
  if (limit < 1 || limit > 50) throw ArgumentError('limit must be 1..50');
  final playlistUri = Uri.tryParse(args.first);
  String text;
  if (playlistUri != null && ['http', 'https'].contains(playlistUri.scheme)) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await (await client.getUrl(
        playlistUri,
      )).close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('Playlist HTTP ${response.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        bytes.addAll(chunk);
        if (bytes.length > 8 * 1024 * 1024) {
          throw StateError('Playlist exceeds 8 MiB');
        }
      }
      text = utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  } else {
    text = await File(args.first).readAsString();
  }
  final urls = prepareM3uForPlayback(
    text,
  ).split('\n').where((s) => s.isNotEmpty && !s.startsWith('#')).toList();
  stdout.writeln(
    jsonEncode({
      'sources': urls.length,
      'note':
          'HTTP/container probe only; decoder support requires device playback',
    }),
  );
  final count = limit < urls.length ? limit : urls.length;
  for (var i = 0; i < count; i++) {
    final index = count == 1 ? 0 : i * (urls.length - 1) ~/ (count - 1);
    stdout.writeln(jsonEncode(await _probe(urls[index], index)));
  }
}

Future<Map<String, Object?>> _probe(String input, int index) async {
  final source = PlaybackSource.parse(input);
  final uri = Uri.parse(source.url);
  // Signed queries and credentials are intentionally omitted from output.
  final result = <String, Object?>{
    'index': index,
    'host': uri.host,
    'path': uri.path,
    'declaredFormat': source.format.name,
  };
  if (!['http', 'https'].contains(uri.scheme)) {
    return {...result, 'status': 'requires native protocol probe'};
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  client.userAgent =
      source.headers.entries
          .where((e) => e.key.toLowerCase() == 'user-agent')
          .firstOrNull
          ?.value ??
      'XPlayer';
  final watch = Stopwatch()..start();
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));
    source.headers.forEach((key, value) => request.headers.set(key, value));
    final response = await request.close().timeout(const Duration(seconds: 10));
    result.addAll({
      'http': response.statusCode,
      'contentType': response.headers.contentType?.mimeType,
      'redirects': response.redirects.length,
    });
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      bytes.addAll(chunk.take(4096 - bytes.length));
      if (bytes.length >= 376) break;
    }
    final prefix = utf8.decode(bytes, allowMalformed: true).trimLeft();
    final container = prefix.startsWith('#EXTM3U')
        ? 'hls'
        : bytes.length >= 3 &&
              bytes[0] == 0x46 &&
              bytes[1] == 0x4c &&
              bytes[2] == 0x56
        ? 'flv'
        : bytes.length > 188 && bytes[0] == 0x47 && bytes[188] == 0x47
        ? 'mpeg-ts'
        : prefix.toLowerCase().startsWith('<!doctype html') ||
              prefix.toLowerCase().startsWith('<html')
        ? 'html'
        : 'unknown';
    result.addAll({
      'payload': container,
      'bytesSampled': bytes.length,
      'elapsedMs': watch.elapsedMilliseconds,
    });
  } catch (e) {
    result['error'] = e is TimeoutException
        ? 'timeout'
        : e.runtimeType.toString();
  } finally {
    client.close(force: true);
  }
  return result;
}
