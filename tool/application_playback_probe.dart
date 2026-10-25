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
      final directory = await getApplicationSupportDirectory();
      Future<void> checkpoint({required bool complete}) async {
        await File('${directory.path}/application_probe.json').writeAsString(
          jsonEncode({
            'probeVersion': 2,
            'platform': Platform.operatingSystem,
            'complete': complete,
            'passed': results.where((r) => r['passed'] == true).length,
            'total': results.length,
            'results': results,
          }),
          flush: true,
        );
      }

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
            Duration? previousPosition;
            var forwardProgress = Duration.zero;
            final playingWatch = Stopwatch()..start();
            final minimumPlayback = Duration(
              seconds: (entry['minPlaybackSeconds'] as int? ?? 2).clamp(2, 10),
            );
            final deadline = DateTime.now().add(const Duration(seconds: 15));
            while (DateTime.now().isBefore(deadline)) {
              final value = backend.notifier.value;
              final diag =
                  backend.diagnostics?.value ?? const <String, dynamic>{};
              if (value.hasError) {
                throw StateError(value.errorDescription ?? 'Playback error');
              }
              if (value.isPlaying && !value.isBuffering) {
                if (previousPosition != null) {
                  final delta = value.position - previousPosition;
                  if (delta > Duration.zero &&
                      delta < const Duration(seconds: 2)) {
                    forwardProgress += delta;
                  }
                }
                previousPosition = value.position;
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
                      ? diag['audioSampleFormat'] != null &&
                            '${diag['audioOutputDriver'] ?? ''}'.isNotEmpty &&
                            diag['audioOutputDriver'] != 'null' &&
                            '${diag['audioOutputParams'] ?? ''}'.isNotEmpty &&
                            diag['muted'] != 'yes' &&
                            (double.tryParse('${diag['volume']}') ?? 0) > 0
                      : backend is NativePlayerBackend
                      ? diag['audioOutputStarted'] == true
                      : (await backend.getAudioTracks()).isNotEmpty);
              if (videoReady &&
                  audioReady &&
                  playingWatch.elapsed >= minimumPlayback &&
                  forwardProgress >= minimumPlayback) {
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
                  'diagnostics': Map<String, dynamic>.of(diag),
                });
                if (entry['testPauseResume'] == true) {
                  // Reuse the same engine/audio session through a pause cycle.
                  await backend.pause();
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                  final resumePosition = backend.notifier.value.position;
                  final resumeFrames =
                      backend.diagnostics?.value['renderedFrames'] as num?;
                  await backend.play();
                  await Future<void>.delayed(const Duration(seconds: 3));
                  final resumed = backend.notifier.value;
                  if (resumed.hasError ||
                      !resumed.isPlaying ||
                      (backend is NativePlayerBackend
                          ? (backend.diagnostics?.value['renderedFrames']
                                        as num? ??
                                    0) <=
                                (resumeFrames ?? 0)
                          : resumed.position == resumePosition)) {
                    throw StateError('Pause/resume did not restore playback');
                  }
                  attempt['pauseResumePassed'] = true;
                }
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            if (attempt['passed'] != true) {
              throw TimeoutException('Output or clock did not progress');
            }
          } catch (error) {
            result['passed'] = false;
            attempt.addAll({
              'passed': false,
              'error': redactPlaybackLog('$error'),
              'diagnostics': backend.diagnostics?.value,
              'elapsedMs': watch.elapsedMilliseconds,
            });
          } finally {
            if (mounted) setState(() => _backend = null);
            WidgetsBinding.instance.ensureVisualUpdate();
            // An occluded desktop window may suspend frames. A test must still
            // release its audio device rather than waiting forever here.
            await WidgetsBinding.instance.endOfFrame.timeout(
              const Duration(seconds: 2),
              onTimeout: () {},
            );
            await backend.dispose();
          }
          attempts.add(attempt);
        } while (result['passed'] != true &&
            plan.advance(errorDescription: attempts.last['error'] as String?));
        results.add(result);
        await checkpoint(complete: false);
        // ignore: avoid_print
        print('XPLAYER_APPLICATION_PROBE ${jsonEncode(result)}');
      }
      if (results.isEmpty) throw StateError('No matching sources');
      final report = {
        'probeVersion': 2,
        'platform': Platform.operatingSystem,
        'passed': results.where((r) => r['passed'] == true).length,
        'total': results.length,
        'results': results,
      };
      await checkpoint(complete: true);
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
