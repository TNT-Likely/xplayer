import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:xplayer_player/playback.dart';

/// Runs libmpv without a window/audio output. Tests decoding, not GPU rendering.
/// dart run packages/xplayer_player/tool/probe_decoder.dart --libmpv=/path/to/libmpv <URLs/files...>
Future<void> main(List<String> args) async {
  final library = args
      .where((a) => a.startsWith('--libmpv='))
      .map((a) => a.substring('--libmpv='.length))
      .firstOrNull;
  final inputs = args.where((a) => !a.startsWith('--')).toList();
  final requireAudio = args.contains('--require-audio');
  final requireVideo = args.contains('--require-video');
  final diagnoseErrors = args.contains('--diagnose-errors');
  final nativeLog = args.contains('--native-log');
  final originalSource = args.contains('--original-source');
  final lowerBandwidth = args.contains('--lower-bandwidth');
  final nativeOptions = args
      .where((a) => a.startsWith('--mpv-option='))
      .map((a) => a.substring('--mpv-option='.length));
  if (inputs.isEmpty) {
    stderr.writeln(
      'Provide media URLs/files and optionally --libmpv=/path/to/library',
    );
    exitCode = 64;
    return;
  }
  MediaKit.ensureInitialized(libmpv: library);
  const configuration = PlaybackConfiguration();
  for (final input in inputs) {
    final source = PlaybackSource.parse(input);
    final player = Player(
      configuration: PlayerConfiguration(
        logLevel: nativeLog ? MPVLogLevel.debug : MPVLogLevel.warn,
        vo: 'null',
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
    final progress = Completer<void>();
    final ready = Completer<void>();
    final subscriptions = <StreamSubscription<dynamic>>[];
    final errors = <String>[];
    final watch = Stopwatch()..start();
    final playbackWatch = Stopwatch();
    Duration? firstPosition;
    Duration? previousPosition;
    var forwardSamples = 0;
    final result = <String, Object?>{'source': Uri.parse(source.url).path};
    var stage = 'open';
    try {
      final native = player.platform as NativePlayer;
      subscriptions.add(
        player.stream.log.listen((entry) {
          final status = RegExp(r'HTTP error (\d{3})\b').firstMatch(entry.text);
          if (status != null) {
            result['httpStatus'] = int.parse(status.group(1)!);
          }
        }),
      );
      if (nativeLog) {
        subscriptions.add(
          player.stream.log.listen((entry) {
            stderr.writeln(
              '[+${watch.elapsedMilliseconds}ms ${entry.prefix}/${entry.level}] ${redactPlaybackLog(entry.text).trimRight()}',
            );
          }),
        );
      }
      await native.setProperty('ao', 'null');
      await native.setProperty('hwdec', 'no');
      // media_kit disables video until a VideoController attaches. This CLI
      // uses a null video output, so explicitly enable the video decoder.
      await native.setProperty('vid', 'auto');
      if (!originalSource) {
        for (final entry in configuration.nativeNetworkProperties.entries) {
          await native.setProperty(entry.key, entry.value);
        }
      }
      for (final option in nativeOptions) {
        final equals = option.indexOf('=');
        if (equals <= 0) {
          throw ArgumentError('Expected --mpv-option=name=value');
        }
        await native.setProperty(
          option.substring(0, equals),
          option.substring(equals + 1),
        );
      }
      subscriptions.add(
        player.stream.videoParams.listen((v) {
          if (!ready.isCompleted && (v.w ?? 0) > 0) ready.complete();
        }),
      );
      subscriptions.add(
        player.stream.audioParams.listen((v) {
          if (!ready.isCompleted && v.format != null) ready.complete();
        }),
      );
      subscriptions.add(
        player.stream.position.listen((position) {
          if (!playbackWatch.isRunning) return;
          firstPosition ??= position;
          if (previousPosition != null && position > previousPosition!) {
            forwardSamples++;
          }
          previousPosition = position;
          if (!progress.isCompleted &&
              forwardSamples >= 2 &&
              playbackWatch.elapsed >= const Duration(seconds: 1) &&
              position - firstPosition! >= const Duration(seconds: 1)) {
            progress.complete();
          }
        }),
      );
      subscriptions.add(
        player.stream.error.listen((error) {
          errors.add(error);
          if (!ready.isCompleted) ready.completeError(StateError(error));
        }),
      );
      final prepared = originalSource
          ? source
          : await prepareHlsStartup(
              source,
              preferLowerBandwidth: lowerBandwidth,
            );
      if (!originalSource && source.format == StreamFormat.hls) {
        await native.setProperty('demuxer-lavf-analyzeduration', '1');
      }
      result['hlsRenditionSelected'] = prepared.url != source.url;
      Future<void> open() async {
        await player.open(
          Media(prepared.url, httpHeaders: prepared.headers),
          play: false,
        );
        stage = 'ready';
      }

      await Future.wait([
        open(),
        ready.future,
      ], eagerError: true).timeout(configuration.initializationTimeout);
      stage = 'progress';
      await player.play();
      playbackWatch.start();
      await progress.future.timeout(const Duration(seconds: 15));
      final video = player.state.tracks.video.where(
        (t) => t.id != 'auto' && t.id != 'no',
      );
      final audio = player.state.tracks.audio.where(
        (t) => t.id != 'auto' && t.id != 'no',
      );
      final audioDecoded =
          audio.isNotEmpty && player.state.audioParams.format != null;
      final videoDecoded =
          video.isNotEmpty && (player.state.videoParams.w ?? 0) > 0;
      if (video.isNotEmpty && (player.state.videoParams.w ?? 0) <= 0) {
        throw StateError('Video decoder did not produce video parameters');
      }
      result.addAll({
        'decoded':
            (audioDecoded || (!requireAudio && audio.isEmpty)) &&
            (videoDecoded || (!requireVideo && video.isEmpty)) &&
            errors.isEmpty,
        'videoDecoded': videoDecoded,
        'audioDecoded': audioDecoded,
        'elapsedMs': watch.elapsedMilliseconds,
        'width': player.state.videoParams.w,
        'height': player.state.videoParams.h,
        'video': video.map((t) => t.codec).toList(),
        'audio': audio.map((t) => t.codec).toList(),
        'sampleRate': player.state.audioParams.sampleRate,
        'channels': player.state.audioParams.channelCount,
        'durationMs': player.state.duration.inMilliseconds,
      });
      if (result['decoded'] != true) exitCode = 1;
    } catch (e) {
      result.addAll({
        'decoded': false,
        'error': e.runtimeType.toString(),
        'stage': stage,
        'width': player.state.videoParams.w,
        'height': player.state.videoParams.h,
        'audioReady': player.state.audioParams.format != null,
        'playing': player.state.playing,
        'buffering': player.state.buffering,
      });
      exitCode = 1;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await player.dispose();
    }
    // Do not emit native error messages containing signed/authenticated URLs.
    result['decoderErrorCount'] = errors.length;
    if (diagnoseErrors) {
      result['errors'] = errors.map(redactPlaybackLog).toList();
    }
    stdout.writeln(jsonEncode(result));
  }
}
