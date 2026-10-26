import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:audio_session/audio_session.dart';

import 'audio_session_coordinator.dart';
import 'audio_packet_recovery.dart';
import 'android_gpu_capabilities.dart';
import 'hls_startup.dart';
import 'playback_configuration.dart';
import 'playback_log.dart';
import 'playback_frame_bootstrap.dart';
import 'playback_source.dart';
import 'startup_eof_recovery.dart';
import 'x_player_backend.dart';

/// libmpv/FFmpeg provides a second demuxer/decoder path on every native OS.
class MediaKitBackend implements XPlayerBackend {
  MediaKitBackend({
    this.softwareDecoding = false,
    this.muted = false,
    this.audioOutputDriver,
    this.configuration = const PlaybackConfiguration(),
    this.onLog,
  });

  final bool softwareDecoding;
  final bool muted;
  final PlaybackConfiguration configuration;

  /// Opt-in diagnostic logging. URLs and authentication headers are redacted.
  final void Function(String message)? onLog;

  /// Optional libmpv audio output override. Production playback uses system
  /// output; explicit "null" is reserved for headless decoder validation.
  final String? audioOutputDriver;
  AudioSessionLease? _audioSessionLease;
  static final _appleAudioSession = AudioSessionCoordinator(
    activate: () async {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        ),
      );
      if (!await session.setActive(true)) {
        throw StateError('Audio session activation was denied');
      }
    },
    deactivate: () async {
      await (await AudioSession.instance).setActive(false);
    },
  );
  mk.Player? _player;
  VideoController? _video;
  final _videoOutput = ValueNotifier<VideoController?>(null);
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _notifier = ValueNotifier<XPlayerValue>(const XPlayerValue());
  final _diagnostics = ValueNotifier<Map<String, dynamic>>({
    'engine': 'libmpv',
  });
  Completer<void>? _ready;
  bool _disposed = false;
  bool _started = false;
  final _startupWatch = Stopwatch();
  final _startupEofRecovery = StartupEofRecovery();
  Future<void>? _startupReload;
  bool _playRequested = false;
  late final _audioRecovery = AudioPacketRecovery(
    timeout: configuration.audioPacketRecoveryTimeout,
    errorLimit: configuration.audioPacketErrorLimit,
  );
  Timer? _audioRecoveryTimer;
  bool _audioRecoveryPollInFlight = false;
  int _audioRecoveryGeneration = 0;
  final _audioRecoveryEvidence = <Map<String, Object?>>[];
  Future<void>? _disposal;
  Timer? _videoBootstrap;

  @override
  ValueListenable<XPlayerValue> get notifier => _notifier;
  @override
  ValueListenable<Map<String, dynamic>> get diagnostics => _diagnostics;

  void _update(XPlayerValue value) {
    if (!_disposed) _notifier.value = value;
  }

  void _markReady() {
    if (_disposed || _ready!.isCompleted) return;
    _update(_notifier.value.copyWith(isInitialized: true));
    _ready!.complete();
  }

  void _reportError(String message) {
    if (_disposed || _notifier.value.hasError) return;
    _cancelAudioRecovery();
    final status = _diagnostics.value['httpStatus'];
    final description = status == null ? message : 'HTTP $status: $message';
    _update(
      _notifier.value.copyWith(hasError: true, errorDescription: description),
    );
    if (!(_ready?.isCompleted ?? true)) {
      _ready!.completeError(StateError(description));
    }
  }

  void _cancelAudioRecovery() {
    _audioRecoveryGeneration++;
    _audioRecoveryTimer?.cancel();
    _audioRecoveryTimer = null;
    _audioRecoveryPollInFlight = false;
    _audioRecovery.cancel();
  }

  void _onPlayerError(String message) {
    if (_disposed || _notifier.value.hasError) return;
    if (!AudioPacketRecovery.handles(message)) {
      _reportError(message);
      return;
    }
    if (!_audioRecovery.pending) _audioRecoveryEvidence.clear();
    final decision = _audioRecovery.record(
      _startupWatch.elapsed,
      playing: _playRequested,
    );
    _audioRecoveryGeneration++;
    _audioRecoveryPollInFlight = false;
    _diagnostics.value = {
      ..._diagnostics.value,
      'audioPacketErrors':
          (_diagnostics.value['audioPacketErrors'] as int? ?? 0) + 1,
      'audioRecoveryState': 'pending',
      'lastAudioPacketError': message.trim(),
    };
    if (decision == AudioRecoveryDecision.failed) {
      _failAudioRecovery('Audio packet error budget exceeded');
      return;
    }
    _startAudioRecoveryPolling();
  }

  void _startAudioRecoveryPolling() {
    if (!_disposed && _playRequested && _audioRecovery.pending) {
      _audioRecoveryTimer ??= Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => unawaited(_pollAudioRecovery()),
      );
    }
  }

  void _suspendAudioRecovery() {
    _audioRecovery.pause();
    _audioRecoveryGeneration++;
    _audioRecoveryTimer?.cancel();
    _audioRecoveryTimer = null;
    _audioRecoveryPollInFlight = false;
  }

  void _failAudioRecovery(String message) {
    _diagnostics.value = {
      ..._diagnostics.value,
      'audioRecoveryState': 'failed',
    };
    _reportError(message);
  }

  Future<void> _pollAudioRecovery() async {
    if (_disposed || !_audioRecovery.pending) return;
    final deadline = _audioRecovery.checkDeadline(
      _startupWatch.elapsed,
      playing: _playRequested,
    );
    if (deadline == AudioRecoveryDecision.failed) {
      _failAudioRecovery('Audio did not recover after a packet decoding error');
      return;
    }
    if (!_playRequested || _audioRecoveryPollInFlight) return;
    final player = _player;
    if (player == null) return;
    final generation = _audioRecoveryGeneration;
    _audioRecoveryPollInFlight = true;
    try {
      final text = await (player.platform as mk.NativePlayer)
          .getProperty('audio-pts')
          .timeout(const Duration(milliseconds: 500));
      if (_disposed || generation != _audioRecoveryGeneration) return;
      final driver = _diagnostics.value['audioOutputDriver'];
      final outputReady =
          driver is String &&
          driver.isNotEmpty &&
          (driver != 'null' || audioOutputDriver == 'null') &&
          _diagnostics.value['audioSampleFormat'] != null &&
          '${_diagnostics.value['audioOutputParams'] ?? ''}'.isNotEmpty;
      _audioRecoveryEvidence.add({
        'elapsedMs': _startupWatch.elapsedMilliseconds,
        'audioPts': double.tryParse(text),
        'outputReady': outputReady,
      });
      if (_audioRecoveryEvidence.length > 12) {
        _audioRecoveryEvidence.removeAt(0);
      }
      _diagnostics.value = {
        ..._diagnostics.value,
        'audioRecoveryEvidence': List<Map<String, Object?>>.of(
          _audioRecoveryEvidence,
        ),
      };
      final decision = _audioRecovery.sample(
        _startupWatch.elapsed,
        playing: _playRequested,
        outputReady: outputReady,
        audioPosition: double.tryParse(text),
      );
      if (decision == AudioRecoveryDecision.recovered) {
        _cancelAudioRecovery();
        _diagnostics.value = {
          ..._diagnostics.value,
          'audioRecoveryState': 'recovered',
          'audioRecoveries':
              (_diagnostics.value['audioRecoveries'] as int? ?? 0) + 1,
        };
      } else if (decision == AudioRecoveryDecision.failed) {
        _failAudioRecovery(
          'Audio did not recover after a packet decoding error',
        );
      }
    } on TimeoutException {
      // The independent deadline remains active if the native query stalls.
    } catch (error) {
      if (!_disposed && generation == _audioRecoveryGeneration) {
        _diagnostics.value = {
          ..._diagnostics.value,
          'audioRecoveryProbeError': redactPlaybackLog('$error'),
        };
      }
    } finally {
      if (generation == _audioRecoveryGeneration) {
        _audioRecoveryPollInFlight = false;
      }
    }
  }

  @override
  Future<void> initialize(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    if (_disposed || _started) throw StateError('Backend already used');
    configuration.validate();
    _started = true;
    _startupWatch.start();
    // Lazy initialization lets errors (e.g. missing Linux libmpv) take the
    // normal playback failure path instead of preventing application startup.
    mk.MediaKit.ensureInitialized();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _audioSessionLease = await _appleAudioSession.acquire();
      if (_disposed) {
        await _audioSessionLease!.release();
        throw StateError('Playback cancelled');
      }
    }
    final source = PlaybackSource.parse(url, headers: headers);
    mk.Media? preparedMedia;
    final player = _player = mk.Player(
      configuration: mk.PlayerConfiguration(
        title: 'XPlayer',
        muted: muted,
        logLevel: onLog == null ? mk.MPVLogLevel.warn : mk.MPVLogLevel.debug,
        protocolWhitelist: [
          'file',
          'tcp',
          'tls',
          'http',
          'https',
          'crypto',
          'data',
          'udp',
          'rtp',
          'rtsp',
          'rtmp',
          'rtmps',
        ],
      ),
    );
    _video = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        hwdec: softwareDecoding ? 'no' : null,
        enableHardwareAcceleration: !softwareDecoding,
      ),
    );
    _videoOutput.value = _video;
    // VideoController defers native setup with addPostFrameCallback. An async
    // audio-session acquisition may finish after the last scheduled UI frame;
    // explicitly request one so static/loading screens cannot deadlock setup.
    _videoBootstrap = requestPlaybackFrame(
      () => _video?.platform.isCompleted == false,
    );
    _diagnostics.value = {
      ..._diagnostics.value,
      'decodeMode': softwareDecoding ? 'software' : 'auto',
      'initializationStage': 'videoOutput',
    };
    unawaited(
      _video!.waitUntilFirstFrameRendered.then<void>(
        (_) {
          if (!_disposed) {
            _diagnostics.value = {
              ..._diagnostics.value,
              'firstFrameRendered': true,
              'firstFrameMs': _startupWatch.elapsedMilliseconds,
            };
          }
        },
        onError: (Object error, StackTrace stack) {
          if (_disposed) return;
          _reportError('$error');
        },
      ),
    );
    _ready = Completer<void>();
    _subscriptions.addAll([
      player.stream.log.listen((entry) {
        onLog?.call(
          '[${entry.prefix}/${entry.level}] ${redactPlaybackLog(entry.text).trimRight()}',
        );
        // media_kit forwards selected "error" logs, but misses fatal cplayer
        // failures (including failure to initialize the Android video output).
        // Preserve the first cause instead of replacing it with a later seek
        // warning emitted while the texture output is being reconfigured.
        if (entry.level == 'fatal' && entry.prefix == 'cplayer') {
          _diagnostics.value = {
            ..._diagnostics.value,
            'fatalPlaybackError': redactPlaybackLog(entry.text.trim()),
          };
          _reportError(entry.text.trim());
        }
        final status = RegExp(r'HTTP error (\d{3})\b').firstMatch(entry.text);
        if (status != null) {
          _diagnostics.value = {
            ..._diagnostics.value,
            'httpStatus': int.parse(status.group(1)!),
          };
        }
        if (entry.level == 'error' && entry.prefix.startsWith('ao/')) {
          _diagnostics.value = {
            ..._diagnostics.value,
            'audioOutputError': entry.text.trim(),
          };
        }
      }),
      player.stream.playing.listen(
        (v) => _update(_notifier.value.copyWith(isPlaying: v)),
      ),
      player.stream.buffering.listen(
        (v) => _update(_notifier.value.copyWith(isBuffering: v)),
      ),
      player.stream.position.listen((v) {
        _startupEofRecovery.observePosition(v);
        _update(_notifier.value.copyWith(position: v));
      }),
      player.stream.completed.listen((completed) {
        // mpv 0.36 / FFmpeg can exhaust fMP4 HLS after the first Android
        // Surface attachment issues an internal seek. Reopen the demuxer once
        // with the now-established surface; normal EOF and user seeks never
        // enter this path. This preserves seeking instead of disabling it.
        if (!completed ||
            _disposed ||
            kIsWeb ||
            defaultTargetPlatform != TargetPlatform.android ||
            source.format != StreamFormat.hls ||
            preparedMedia == null ||
            !_startupEofRecovery.takeRecovery(player.state.duration)) {
          return;
        }
        _startupReload = () async {
          try {
            await _video!.waitUntilFirstFrameRendered.timeout(
              configuration.initializationTimeout,
            );
            if (_disposed) return;
            _diagnostics.value = {
              ..._diagnostics.value,
              'startupHlsReloads': 1,
            };
            await player.open(preparedMedia!, play: false);
            if (!_disposed && _playRequested) await player.play();
          } catch (error) {
            _reportError(
              'HLS startup recovery failed: ${redactPlaybackLog('$error')}',
            );
          }
        }();
      }),
      player.stream.duration.listen(
        (v) => _update(_notifier.value.copyWith(duration: v)),
      ),
      player.stream.videoParams.listen((v) {
        final width = v.dw ?? v.w ?? 0;
        final height = v.dh ?? v.h ?? 0;
        if (width <= 0 || height <= 0) return;
        _update(
          _notifier.value.copyWith(
            size: Size(width.toDouble(), height.toDouble()),
          ),
        );
        _diagnostics.value = {
          ..._diagnostics.value,
          'videoHardware': v.hwPixelformat != null,
          'pixelFormat': v.pixelformat,
        };
        _markReady();
      }),
      player.stream.audioParams.listen((v) {
        if (v.format != null) {
          _diagnostics.value = {
            ..._diagnostics.value,
            'audioSampleFormat': v.format,
            'audioSampleRate': v.sampleRate,
            'audioChannels': v.channelCount,
          };
          _markReady();
        }
      }),
      player.stream.tracks.listen((v) {
        final video = v.video.where((t) => t.id != 'auto' && t.id != 'no');
        final audio = v.audio.where((t) => t.id != 'auto' && t.id != 'no');
        _diagnostics.value = {
          ..._diagnostics.value,
          if (video.isNotEmpty) 'videoMime': video.first.codec,
          if (audio.isNotEmpty) 'audioMime': audio.first.codec,
          if (video.isNotEmpty) 'videoDecoder': video.first.decoder,
          if (audio.isNotEmpty) 'audioDecoder': audio.first.decoder,
        };
      }),
      player.stream.error.listen(_onPlayerError),
    ]);
    Future<void> open() async {
      await _video!.platform.future;
      if (_disposed) throw StateError('Playback cancelled');
      final native = player.platform as mk.NativePlayer;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final capabilities = await queryAndroidGpuCapabilities();
        if (_disposed) throw StateError('Playback cancelled');
        _diagnostics.value = {
          ..._diagnostics.value,
          'androidEglCapabilities': capabilities,
        };
        if (capabilities['needsDebugContext'] == true) {
          await native.setProperty('gpu-debug', 'yes');
        }
      }
      // Decoder parameters alone do not prove that a speaker output opened.
      // Keep output, mute and volume visible across pause/resume and rerouting.
      for (final property in {
        'current-ao': 'audioOutputDriver',
        'audio-out-params': 'audioOutputParams',
        'audio-device': 'audioDevice',
        'mute': 'muted',
        'volume': 'volume',
        'current-vo': 'videoOutputDriver',
        'vo-configured': 'videoOutputConfigured',
        'video-out-params': 'videoOutputParams',
      }.entries) {
        await native.observeProperty(property.key, (value) async {
          if (_disposed) return;
          _diagnostics.value = {
            ..._diagnostics.value,
            property.value: value,
            if (property.key == 'audio-out-params' &&
                value.isNotEmpty &&
                !_diagnostics.value.containsKey('audioOutputMs'))
              'audioOutputMs': _startupWatch.elapsedMilliseconds,
          };
        });
      }
      // Overseas HLS connections can exceed media_kit's five-second default.
      // Keep the live cache in memory rather than requiring a writable native
      // cache directory, which may be absent in sandboxed applications.
      for (final entry in configuration.nativeNetworkProperties.entries) {
        await native.setProperty(entry.key, entry.value);
      }
      _diagnostics.value = {
        ..._diagnostics.value,
        'initializationStage': 'manifest',
      };
      final prepared = configuration.resolveHlsVariants
          ? await prepareHlsStartup(
              source,
              preferLowerBandwidth:
                  softwareDecoding &&
                  configuration.lowerBandwidthOnSoftwareFallback,
              timeout: configuration.hlsProbeTimeout,
            )
          : source;
      final manifestReadyMs = _startupWatch.elapsedMilliseconds;
      if (_disposed) throw StateError('Playback cancelled');
      if (source.format == StreamFormat.hls) {
        await native.setProperty('demuxer-lavf-analyzeduration', '1');
      }
      _diagnostics.value = {
        ..._diagnostics.value,
        'initializationStage': 'open',
        'manifestReadyMs': manifestReadyMs,
        'hlsRenditionSelected': prepared.url != source.url,
        if (prepared.url != source.url)
          'hlsSelection':
              softwareDecoding && configuration.lowerBandwidthOnSoftwareFallback
              ? 'lowerBandwidth'
              : 'highestBandwidth',
      };
      if (audioOutputDriver != null) {
        await (player.platform as mk.NativePlayer).setProperty(
          'ao',
          audioOutputDriver!,
        );
      }
      if (_disposed) throw StateError('Playback cancelled');
      preparedMedia = mk.Media(prepared.url, httpHeaders: prepared.headers);
      await player.open(preparedMedia!, play: false);
      if (!_disposed) {
        _diagnostics.value = {
          ..._diagnostics.value,
          'initializationStage': 'decoder',
        };
      }
    }

    try {
      await Future.wait([
        open(),
        _ready!.future,
      ], eagerError: true).timeout(configuration.initializationTimeout);
    } catch (error) {
      _reportError(redactPlaybackLog('$error'));
      rethrow;
    }
    if (!_disposed) {
      _diagnostics.value = {
        ..._diagnostics.value,
        'initializationStage': 'ready',
        'initializedMs': _startupWatch.elapsedMilliseconds,
      };
    }
  }

  @override
  Future<void> play() async {
    if (_disposed) return;
    _playRequested = true;
    await _startupReload;
    if (_disposed) return;
    if (_audioSessionLease != null) {
      await _appleAudioSession.reactivate();
      if (_disposed) return;
    }
    await _player?.play();
    _startAudioRecoveryPolling();
  }

  @override
  Future<void> pause() async {
    _playRequested = false;
    _suspendAudioRecovery();
    await _player?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _startupEofRecovery.userSeek();
    _suspendAudioRecovery();
    await _startupReload;
    if (_disposed) return;
    try {
      await _player?.seek(position);
    } finally {
      _startAudioRecoveryPolling();
    }
  }

  @override
  Future<List<AudioTrack>> getAudioTracks() async {
    final player = _player;
    if (player == null) return [];
    return player.state.tracks.audio
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(
          (t) => AudioTrack(
            id: t.id,
            label: t.title,
            language: t.language,
            codec: t.codec,
            channels: t.channelscount,
            isSelected: player.state.track.audio.id == t.id,
          ),
        )
        .toList();
  }

  @override
  Future<void> selectAudioTrack(String id) async {
    final player = _player;
    if (player == null) return;
    final track = player.state.tracks.audio.firstWhere((t) => t.id == id);
    await player.setAudioTrack(track);
  }

  @override
  Future<void> setSurfaceBounds(Rect? rect, double devicePixelRatio) async {}

  @override
  Widget buildView() {
    return ValueListenableBuilder<VideoController?>(
      valueListenable: _videoOutput,
      builder: (_, video, __) => video == null
          ? const SizedBox.shrink()
          : Video(
              controller: video,
              controls: NoVideoControls,
              fit: BoxFit.contain,
            ),
    );
  }

  @override
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelAudioRecovery();
    if (_ready != null && !_ready!.isCompleted) {
      _ready!.completeError(StateError('Playback cancelled'));
    }
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    try {
      await _player?.dispose();
    } finally {
      try {
        await _audioSessionLease?.release();
      } catch (_) {}
      _player = null;
      _video = null;
      _videoBootstrap?.cancel();
      _videoOutput.dispose();
      _notifier.dispose();
      _diagnostics.dispose();
    }
  }
}
