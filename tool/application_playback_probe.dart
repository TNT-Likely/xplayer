import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/services/player/native_player_backend.dart';
import 'package:xplayer/services/player/player_backend_factory.dart';
import 'package:xplayer_player/xplayer_player.dart';

/// Explicit host test: exercise the actual backend factory and fallback order.
/// Run through playback_device_probe.dart with PLAYBACK_PROBE_APPLICATION=true.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _ApplicationProbe()));
}

class _ApplicationProbe extends StatefulWidget {
  const _ApplicationProbe();
  @override
  State<_ApplicationProbe> createState() => _ApplicationProbeState();
}

class _ApplicationProbeState extends State<_ApplicationProbe> {
  XPlayerBackend? _backend;
  String _status = 'Loading application playback probe';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final results = <Map<String, Object?>>[];
    try {
      const configUrl = String.fromEnvironment('PLAYBACK_PROBE_CONFIG');
      const filter = String.fromEnvironment('PLAYBACK_PROBE_FILTER');
      final response = await (await client.getUrl(
        Uri.parse(configUrl),
      )).close().timeout(const Duration(seconds: 10));
      final config =
          jsonDecode(
                await utf8.decoder
                    .bind(response.timeout(const Duration(seconds: 10)))
                    .join(),
              )
              as Map;
      final platform = Platform.isAndroid
          ? PlaybackPlatform.android
          : Platform.isIOS
          ? PlaybackPlatform.ios
          : Platform.isMacOS
          ? PlaybackPlatform.macos
          : Platform.isWindows
          ? PlaybackPlatform.windows
          : PlaybackPlatform.linux;
      for (final entry in config['sources'] as List) {
        if (filter.isNotEmpty && !(entry['name'] as String).contains(filter)) {
          continue;
        }
        final source = PlaybackSource.parse(entry['url'] as String);
        final plan = PlaybackPlan(
          platform: platform,
          source: source,
          nativeEnabled: true,
        );
        final attempts = <Map<String, Object?>>[];
        final result = <String, Object?>{
          'name': entry['name'],
          'passed': false,
          'attempts': attempts,
        };
        do {
          final backend = createPlayerBackend(plan.current);
          final attempt = <String, Object?>{'engine': plan.current.name};
          final watch = Stopwatch()..start();
          setState(() {
            _backend = backend;
            _status = '${entry['name']} / ${plan.current.name}';
          });
          try {
            await backend
                .initialize(source.url, headers: source.headers)
                .timeout(const Duration(seconds: 22));
            await backend.setSurfaceBounds(null, 1);
            await backend.play();
            Duration? start;
            final deadline = DateTime.now().add(const Duration(seconds: 15));
            while (DateTime.now().isBefore(deadline)) {
              final value = backend.notifier.value;
              final diag =
                  backend.diagnostics?.value ?? const <String, dynamic>{};
              if (value.hasError) {
                throw StateError(value.errorDescription ?? 'Playback error');
              }
              if (value.isPlaying && !value.isBuffering) {
                start ??= value.position;
              }
              final videoReady =
                  entry['expectVideo'] == false ||
                  (backend is NativePlayerBackend
                      ? (diag['renderedFrames'] as num? ?? 0) > 0
                      : backend is MediaKitBackend
                      ? diag['firstFrameRendered'] == true
                      : value.size.width > 0);
              final audioReady =
                  entry['expectAudio'] == false ||
                  (backend is MediaKitBackend
                      ? diag['audioSampleFormat'] != null
                      : (await backend.getAudioTracks()).isNotEmpty);
              if (videoReady &&
                  audioReady &&
                  start != null &&
                  value.position - start >= const Duration(seconds: 2)) {
                result['passed'] = true;
                attempt.addAll({
                  'passed': true,
                  'elapsedMs': watch.elapsedMilliseconds,
                  'width': value.size.width,
                  'height': value.size.height,
                  'audio': diag['audioMime'],
                  'video': diag['videoMime'],
                  'renderedFrames': diag['renderedFrames'],
                  'positionMs': value.position.inMilliseconds,
                });
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            if (attempt['passed'] != true) {
              throw TimeoutException('Output or clock did not progress');
            }
          } catch (error) {
            attempt.addAll({
              'passed': false,
              'error': redactPlaybackLog('$error'),
              'diagnostics': backend.diagnostics?.value,
              'elapsedMs': watch.elapsedMilliseconds,
            });
          } finally {
            if (mounted) setState(() => _backend = null);
            await WidgetsBinding.instance.endOfFrame;
            await backend.dispose();
          }
          attempts.add(attempt);
        } while (result['passed'] != true && plan.advance());
        results.add(result);
        // ignore: avoid_print
        print('XPLAYER_APPLICATION_PROBE ${jsonEncode(result)}');
      }
      if (results.isEmpty) throw StateError('No matching sources');
      final report = {
        'platform': Platform.operatingSystem,
        'passed': results.where((r) => r['passed'] == true).length,
        'total': results.length,
        'results': results,
      };
      final directory = await getApplicationSupportDirectory();
      await File(
        '${directory.path}/application_probe.json',
      ).writeAsString(jsonEncode(report));
      setState(
        () => _status = 'Completed: ${report['passed']}/${report['total']}',
      );
      // ignore: avoid_print
      print('XPLAYER_APPLICATION_PROBE_DONE ${jsonEncode(report)}');
    } catch (error) {
      setState(() => _status = redactPlaybackLog('$error'));
      // ignore: avoid_print
      print(
        'XPLAYER_APPLICATION_PROBE_SETUP_FAILED ${redactPlaybackLog('$error')}',
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _backend is NativePlayerBackend
        ? Colors.transparent
        : Colors.black,
    body: Stack(
      children: [
        if (_backend != null) Positioned.fill(child: _backend!.buildView()),
        SafeArea(
          child: Text(_status, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
