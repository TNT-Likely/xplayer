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
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await (await client.getUrl(
        Uri.parse(configUrl),
      )).close().timeout(const Duration(seconds: 10));
      final config =
          jsonDecode(
                await utf8.decoder
                    .bind(response)
                    .join()
                    .timeout(const Duration(seconds: 10)),
              )
              as Map;
      final results = <Map<String, Object?>>[];
      Map<String, Object?>? activeCase;
      final directory = await getApplicationSupportDirectory();
      Future<void> checkpoint({required bool complete}) async {
        await File('${directory.path}/codec_probe.json').writeAsString(
          jsonEncode({
            'probeVersion': 4,
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
            'complete': complete,
            'passed': results.where((r) => r['passed'] == true).length,
            'total': results.length,
            'results': results,
            'activeCase': activeCase,
          }),
          flush: true,
        );
      }

      await checkpoint(complete: false);
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
            configuration: PlaybackConfiguration(
              hlsLiveStartSegments: entry['hlsLiveStartSegments'] as int?,
              audioPacketErrorLimit:
                  entry['audioPacketErrorLimit'] as int? ?? 8,
            ),
            muted: !const bool.fromEnvironment('PLAYBACK_PROBE_AUDIBLE'),
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
                : const bool.fromEnvironment('PLAYBACK_PROBE_AUDIBLE')
                ? 'system (audible)'
                : 'system (muted)',
          };
          final watch = Stopwatch()..start();
          final playingWatch = Stopwatch();
          final observation = _PlaybackObservation();
          final continuity = entry['continuity'] as Map<String, dynamic>?;
          final maxAvSyncMs = continuity?['maxAvSyncMs'] as int? ?? 150;
          final requiredJumps =
              continuity?['minClockDiscontinuities'] as int? ?? 0;
          final requiredSyncedAudioMs =
              continuity?['minSyncedAudioMs'] as int? ?? 0;
          final maxResyncMs = continuity?['maxResyncMs'] as int?;
          var lastTelemetry = const Duration(seconds: -1);
          VoidCallback? progressListener;
          try {
            final holdSeconds = (entry['holdSeconds'] as int? ?? 1).clamp(
              1,
              7200,
            );
            final minimumPlayback = Duration(seconds: holdSeconds);
            final mode = software ? 'software' : 'auto';
            await backend
                .initialize(
                  (entry['urlsByMode']?[mode] ?? entry['url']) as String,
                  headers: Map<String, String>.from(
                    entry['headers'] as Map? ?? {},
                  ),
                )
                .timeout(const Duration(seconds: 25));
            progressListener = () {
              if (playingWatch.isRunning) {
                observation.onPlaybackState(
                  backend.notifier.value,
                  playingWatch.elapsed,
                );
              }
            };
            backend.notifier.addListener(progressListener);
            playingWatch.start();
            await backend.play();
            final wallBudget = minimumPlayback + const Duration(seconds: 30);
            var lastSample = const Duration(seconds: -5);
            var samples = 0;
            var bufferingSamples = 0;
            var videoReady = false;
            var audioReady = false;
            while (playingWatch.elapsed < wallBudget) {
              final value = backend.notifier.value;
              if (value.hasError) {
                throw StateError(value.errorDescription ?? 'Playback error');
              }
              final diag = backend.diagnostics.value;
              if (playingWatch.elapsed - observation.lastAdvance >
                  const Duration(seconds: 20)) {
                throw StateError(
                  'Playback clock stalled for more than 20 seconds',
                );
              }
              videoReady =
                  entry['expectVideo'] == false ||
                  (diag['firstFrameRendered'] == true &&
                      diag['videoOutputConfigured'] == 'yes' &&
                      '${diag['videoOutputParams'] ?? ''}'.isNotEmpty);
              audioReady =
                  entry['expectAudio'] == false ||
                  (diag['audioSampleFormat'] != null &&
                      (const bool.fromEnvironment(
                            'PLAYBACK_PROBE_NULL_AUDIO',
                          ) ||
                          ('${diag['audioOutputDriver'] ?? ''}'.isNotEmpty &&
                              diag['audioOutputDriver'] != 'null' &&
                              '${diag['audioOutputParams'] ?? ''}'
                                  .isNotEmpty)));
              if (continuity != null &&
                  videoReady &&
                  audioReady &&
                  playingWatch.elapsed - lastTelemetry >=
                      const Duration(milliseconds: 500)) {
                lastTelemetry = playingWatch.elapsed;
                final metrics = await backend.readPlaybackMetrics();
                final current = backend.notifier.value;
                observation.onMetrics(
                  metrics,
                  elapsed: playingWatch.elapsed,
                  advancing: current.isPlaying && !current.isBuffering,
                  maxAvSyncMs: maxAvSyncMs,
                );
              }
              if (playingWatch.elapsed - lastSample >=
                  const Duration(seconds: 5)) {
                lastSample = playingWatch.elapsed;
                samples++;
                if (value.isBuffering) bufferingSamples++;
                activeCase = {
                  'name': entry['name'],
                  'mode': mode,
                  'sample': samples,
                  'elapsedMs': playingWatch.elapsedMilliseconds,
                  'positionMs': value.position.inMilliseconds,
                  'forwardProgressMs': observation.progress.inMilliseconds,
                  'buffering': value.isBuffering,
                  if (continuity != null)
                    'continuity': observation.metrics(playingWatch.elapsed),
                };
                await checkpoint(complete: false);
              }
              if (videoReady &&
                  audioReady &&
                  playingWatch.elapsed >= minimumPlayback &&
                  observation.progress >= minimumPlayback &&
                  observation.clockDiscontinuities >= requiredJumps &&
                  observation.syncedAudioMs >= requiredSyncedAudioMs &&
                  diag['audioRecoveryState'] != 'pending') {
                if (entry['expectFailure'] == true) {
                  throw StateError('Expected decoding failure did not happen');
                }
                if ((diag['audioRecoveries'] as int? ?? 0) <
                    (entry['minAudioRecoveries'] as int? ?? 0)) {
                  throw StateError('Expected audio recovery was not observed');
                }
                if (maxResyncMs != null &&
                    (observation.resyncMs == null ||
                        observation.resyncMs! > maxResyncMs)) {
                  throw StateError(
                    'Audio/video resynchronization exceeded ${maxResyncMs}ms',
                  );
                }
                playingWatch.stop();
                if (entry['testPauseResume'] == true) {
                  await backend.pause();
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                  final beforeResume = backend.notifier.value.position;
                  await backend.play();
                  await Future<void>.delayed(const Duration(seconds: 3));
                  final resumed = backend.notifier.value;
                  if (resumed.hasError ||
                      !resumed.isPlaying ||
                      resumed.position == beforeResume) {
                    throw StateError('Pause/resume did not restore playback');
                  }
                  result['pauseResumePassed'] = true;
                }
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
                  'observedSeconds': playingWatch.elapsed.inSeconds,
                  'audioRecoveries': diag['audioRecoveries'] ?? 0,
                  'audioPacketErrors': diag['audioPacketErrors'] ?? 0,
                  'audioRecoveryEvidence': diag['audioRecoveryEvidence'],
                  'samples': samples,
                  'bufferingSamples': bufferingSamples,
                  'audioOutputDriver': diag['audioOutputDriver'],
                  'audioOutputParams': diag['audioOutputParams'],
                  'audioOutputMs': diag['audioOutputMs'],
                  'firstFrameMs': diag['firstFrameMs'],
                  'videoOutputDriver': diag['videoOutputDriver'],
                  'videoOutputConfigured': diag['videoOutputConfigured'],
                  'videoHardware': diag['videoHardware'],
                  'startupHlsReloads': diag['startupHlsReloads'] ?? 0,
                  'androidEglCapabilities': diag['androidEglCapabilities'],
                });
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            if (result['passed'] != true) {
              if (videoReady && audioReady) {
                throw TimeoutException(
                  'Playback advanced ${observation.progress.inMilliseconds}ms '
                  'of ${minimumPlayback.inMilliseconds}ms in '
                  '${playingWatch.elapsedMilliseconds}ms '
                  '(clock jumps: ${observation.clockDiscontinuities}, '
                  'synchronized audio: ${observation.syncedAudioMs}ms)',
                );
              }
              throw TimeoutException(
                'Rendered frame and audio did not become ready',
              );
            }
          } catch (e) {
            // Keep actionable diagnostics while removing authenticated URLs.
            final safeError = '$e'.replaceAll(
              RegExp(r'(?:https?|rtmps?|rtsp)://\S+'),
              '[source URL]',
            );
            result.addAll({
              'passed':
                  entry['expectFailure'] == true &&
                  entry['expectedErrorContains'] is String &&
                  (entry['expectedErrorContains'] as String).isNotEmpty &&
                  safeError.contains(entry['expectedErrorContains'] as String),
              'expectedFailure': entry['expectFailure'] == true,
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
            playingWatch.stop();
            result.addAll({
              'forwardProgressMs': observation.progress.inMilliseconds,
              'playingWallMs': playingWatch.elapsedMilliseconds,
              'hlsLiveStartSegments': entry['hlsLiveStartSegments'],
              if (continuity != null)
                'continuity': observation.metrics(playingWatch.elapsed),
            });
            if (progressListener != null) {
              backend.notifier.removeListener(progressListener);
            }
            if (mounted) setState(() => _backend = null);
            // Persist the playback outcome before potentially blocking teardown.
            activeCase = {
              'name': entry['name'],
              'stage': 'disposing',
              'outcome': result,
            };
            await checkpoint(complete: false);
            WidgetsBinding.instance.ensureVisualUpdate();
            await WidgetsBinding.instance.endOfFrame.timeout(
              const Duration(seconds: 2),
              onTimeout: () {},
            );
            await backend.dispose();
          }
          results.add(result);
          activeCase = null;
          await checkpoint(complete: false);
          // Machine-readable results are collected via adb logcat.
          // ignore: avoid_print
          print('XPLAYER_PROBE ${jsonEncode(result)}');
        }
      }
      final passed = results.where((r) => r['passed'] == true).length;
      if (results.isEmpty) throw StateError('No matching probe sources');
      await checkpoint(complete: true);
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

class _PlaybackObservation {
  static const _jumpThreshold = Duration(seconds: 2);
  Duration progress = Duration.zero;
  Duration lastAdvance = Duration.zero;
  Duration? _previousPosition;
  bool _previouslyBuffering = false;
  Duration? _bufferingSince;
  Duration _bufferingTotal = Duration.zero;
  Duration _longestBuffering = Duration.zero;
  int _bufferingEvents = 0;
  int clockDiscontinuities = 0;
  Duration? _lastJumpAt;
  int? _lastJumpMs;
  int? _previousAudioPtsMs;
  int syncedAudioMs = 0;
  int? resyncMs;
  int? _firstSyncedAtMs;
  int _avSamples = 0;
  int _avSamplesOverLimit = 0;
  int? _peakAvSyncMs;
  Map<String, int> _lastMetrics = const {};

  void onPlaybackState(XPlayerValue value, Duration elapsed) {
    final playing = value.isPlaying && !value.hasError;
    final buffering = playing && value.isBuffering;
    final previous = _previousPosition;
    _previousPosition = playing ? value.position : null;
    if (playing && previous != null) {
      final delta = value.position - previous;
      if (delta >= _jumpThreshold ||
          delta <= const Duration(milliseconds: -500)) {
        if (progress > Duration.zero) {
          clockDiscontinuities++;
          _lastJumpAt = elapsed;
          _lastJumpMs = delta.inMilliseconds;
          resyncMs = null;
          _resetSync();
        }
      } else if (delta > Duration.zero && !buffering && !_previouslyBuffering) {
        progress += delta;
        lastAdvance = elapsed;
      }
    }
    _previouslyBuffering = buffering;
    if (buffering && progress > Duration.zero) {
      if (_bufferingSince == null) {
        _bufferingSince = elapsed;
        _bufferingEvents++;
        _resetSync();
      }
    } else if (_bufferingSince case final start?) {
      final length = elapsed - start;
      _bufferingTotal += length;
      if (length > _longestBuffering) _longestBuffering = length;
      _bufferingSince = null;
    }
  }

  void onMetrics(
    Map<String, int> metrics, {
    required Duration elapsed,
    required bool advancing,
    required int maxAvSyncMs,
  }) {
    _lastMetrics = metrics;
    final audioPtsMs = metrics['audioPtsMs'];
    final offset = metrics['avSyncMs']?.abs();
    if (!advancing || audioPtsMs == null || offset == null) {
      _resetSync();
      return;
    }
    _avSamples++;
    if (_peakAvSyncMs == null || offset > _peakAvSyncMs!) {
      _peakAvSyncMs = offset;
    }
    if (offset > maxAvSyncMs) {
      _avSamplesOverLimit++;
      _resetSync();
      return;
    }
    final previousAudioPtsMs = _previousAudioPtsMs;
    if (previousAudioPtsMs != null) {
      final delta = audioPtsMs - previousAudioPtsMs;
      if (delta > 0 && delta < _jumpThreshold.inMilliseconds) {
        syncedAudioMs += delta;
        if (syncedAudioMs >= 1000 && _lastJumpAt != null) {
          resyncMs ??= _firstSyncedAtMs! - _lastJumpAt!.inMilliseconds;
        }
      } else {
        _resetSync();
      }
    }
    _firstSyncedAtMs ??= elapsed.inMilliseconds;
    _previousAudioPtsMs = audioPtsMs;
  }

  void _resetSync() {
    _previousAudioPtsMs = null;
    _firstSyncedAtMs = null;
    syncedAudioMs = 0;
  }

  Map<String, Object?> metrics(Duration elapsed) {
    final ongoingBuffering = _bufferingSince == null
        ? Duration.zero
        : elapsed - _bufferingSince!;
    return {
      'bufferingEvents': _bufferingEvents,
      'bufferingMs': (_bufferingTotal + ongoingBuffering).inMilliseconds,
      'maxBufferingMs':
          (ongoingBuffering > _longestBuffering
                  ? ongoingBuffering
                  : _longestBuffering)
              .inMilliseconds,
      'clockDiscontinuities': clockDiscontinuities,
      'lastClockDiscontinuityAtMs': _lastJumpAt?.inMilliseconds,
      'lastClockDiscontinuityDeltaMs': _lastJumpMs,
      'avSyncSamples': _avSamples,
      'avSyncSamplesOverLimit': _avSamplesOverLimit,
      'peakAvSyncMs': _peakAvSyncMs,
      'syncedAudioMs': syncedAudioMs,
      'resyncMs': resyncMs,
      ..._lastMetrics,
    };
  }
}
