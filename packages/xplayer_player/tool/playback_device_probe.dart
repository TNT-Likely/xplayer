import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xplayer_player/xplayer_player.dart';
import 'package:path_provider/path_provider.dart';

/// Opt-in device harness. Android uses a separate application ID.
/// flutter build apk --debug -t tool/playback_device_probe.dart \
///   --dart-define=PLAYBACK_PROBE_CONFIG=http://127.0.0.1:PORT/config.json
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _PlaybackProbe()));
}

class _PlaybackProbe extends StatefulWidget {
  const _PlaybackProbe();
  @override
  State<_PlaybackProbe> createState() => _PlaybackProbeState();
}

class _PlaybackProbeState extends State<_PlaybackProbe> {
  MediaKitBackend? _backend;
  String _status = 'Loading probe configuration';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    const configUrl = String.fromEnvironment('PLAYBACK_PROBE_CONFIG');
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(
        Uri.parse(configUrl),
      )).close();
      final config =
          jsonDecode(await utf8.decoder.bind(response).join()) as Map;
      final results = <Map<String, Object?>>[];
      const filter = String.fromEnvironment('PLAYBACK_PROBE_FILTER');
      const selectedMode = String.fromEnvironment('PLAYBACK_PROBE_MODE');
      for (final entry in config['sources'] as List) {
        if (filter.isNotEmpty && !(entry['name'] as String).contains(filter)) {
          continue;
        }
        for (final software in [false, true]) {
          if (selectedMode.isNotEmpty &&
              selectedMode != (software ? 'software' : 'auto')) {
            continue;
          }
          if (!mounted) return;
          final backend = MediaKitBackend(
            softwareDecoding: software,
            muted: true,
            audioOutputDriver:
                const bool.fromEnvironment('PLAYBACK_PROBE_NULL_AUDIO')
                ? 'null'
                : null,
            onLog: const bool.fromEnvironment('PLAYBACK_PROBE_DEBUG')
                ? (message) {
                    // ignore: avoid_print
                    print('XPLAYER_NATIVE $message');
                  }
                : null,
          );
          setState(() {
            _backend = backend;
            _status = '${entry['name']} (${software ? 'software' : 'auto'})';
          });
          final result = <String, Object?>{
            'name': entry['name'],
            'mode': software ? 'software' : 'auto',
            'audioOutput':
                const bool.fromEnvironment('PLAYBACK_PROBE_NULL_AUDIO')
                ? 'null (decoder test)'
                : 'system (muted)',
          };
          final watch = Stopwatch()..start();
          try {
            await backend
                .initialize(entry['url'] as String)
                .timeout(const Duration(seconds: 25));
            await backend.play();
            Duration? firstPosition;
            final deadline = DateTime.now().add(const Duration(seconds: 15));
            while (DateTime.now().isBefore(deadline)) {
              final value = backend.notifier.value;
              if (value.hasError) {
                throw StateError(value.errorDescription ?? 'Playback error');
              }
              if (value.isPlaying && !value.isBuffering) {
                firstPosition ??= value.position;
              }
              final diag = backend.diagnostics.value;
              final videoReady =
                  entry['expectVideo'] == false ||
                  (diag['firstFrameRendered'] == true &&
                      diag['videoOutputConfigured'] == 'yes' &&
                      '${diag['videoOutputParams'] ?? ''}'.isNotEmpty);
              final audioReady =
                  entry['expectAudio'] == false ||
                  diag['audioSampleFormat'] != null;
              if (videoReady &&
                  audioReady &&
                  firstPosition != null &&
                  value.position - firstPosition >=
                      const Duration(seconds: 1)) {
                result.addAll({
                  'passed': true,
                  'width': value.size.width,
                  'height': value.size.height,
                  'audio': diag['audioMime'],
                  'video': diag['videoMime'],
                  'sampleRate': diag['audioSampleRate'],
                  'channels': diag['audioChannels'],
                  'firstFrameRendered': diag['firstFrameRendered'] == true,
                  'hlsSelection': diag['hlsSelection'],
                  'durationMs': value.duration.inMilliseconds,
                  'elapsedMs': watch.elapsedMilliseconds,
                  'audioOutputDriver': diag['audioOutputDriver'],
                  'audioOutputParams': diag['audioOutputParams'],
                  'audioOutputMs': diag['audioOutputMs'],
                  'firstFrameMs': diag['firstFrameMs'],
                  'videoOutputDriver': diag['videoOutputDriver'],
                  'videoOutputConfigured': diag['videoOutputConfigured'],
                  'androidEglCapabilities': diag['androidEglCapabilities'],
                });
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            if (result['passed'] != true) {
              throw TimeoutException(
                'Rendered frame, audio and advancing clock did not become ready',
              );
            }
          } catch (e) {
            // Keep actionable diagnostics while removing authenticated URLs.
            final safeError = '$e'.replaceAll(
              RegExp(r'(?:https?|rtmps?|rtsp)://\S+'),
              '[source URL]',
            );
            result.addAll({
              'passed': false,
              'error': e.runtimeType.toString(),
              'message': safeError,
              'diagnostics': backend.diagnostics.value,
              'positionMs': backend.notifier.value.position.inMilliseconds,
              'isPlaying': backend.notifier.value.isPlaying,
              'isBuffering': backend.notifier.value.isBuffering,
              'width': backend.notifier.value.size.width,
              'height': backend.notifier.value.size.height,
            });
          } finally {
            if (mounted) setState(() => _backend = null);
            await WidgetsBinding.instance.endOfFrame;
            await backend.dispose();
          }
          results.add(result);
          // Machine-readable results are collected via adb logcat.
          // ignore: avoid_print
          print('XPLAYER_PROBE ${jsonEncode(result)}');
        }
      }
      final passed = results.where((r) => r['passed'] == true).length;
      if (results.isEmpty) throw StateError('No matching probe sources');
      final directory = await getApplicationSupportDirectory();
      await File('${directory.path}/codec_probe.json').writeAsString(
        jsonEncode({
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'passed': passed,
          'total': results.length,
          'results': results,
        }),
        flush: true,
      );
      setState(() => _status = 'Completed: $passed / ${results.length}');
      // ignore: avoid_print
      print(
        'XPLAYER_PROBE_DONE ${jsonEncode({'passed': passed, 'total': results.length})}',
      );
    } catch (e) {
      setState(() => _status = 'Probe setup failed: ${e.runtimeType}');
      // ignore: avoid_print
      print('XPLAYER_PROBE_SETUP_FAILED ${e.runtimeType}');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status, style: const TextStyle(color: Colors.white)),
          ),
        ),
        Expanded(child: _backend?.buildView() ?? const SizedBox.shrink()),
      ],
    ),
  );
}
