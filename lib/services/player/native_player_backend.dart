import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Widget, SizedBox;
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/services/player/buffer_profile.dart';

/// 原生引擎后端:驱动 NativeVideoEngine。视频由底层 SurfaceView 渲染,
/// buildView 返回透明占位(露出 SurfaceView)。
class NativePlayerBackend implements XPlayerBackend {
  static const _method = MethodChannel('native_player');
  static const _events = EventChannel('native_player/events');

  final ValueNotifier<XPlayerValue> _notifier =
      ValueNotifier<XPlayerValue>(const XPlayerValue());
  StreamSubscription? _sub;
  Size _size = Size.zero;
  final ValueNotifier<Map<String, dynamic>> _diag =
      ValueNotifier<Map<String, dynamic>>(const {});

  @override
  ValueListenable<XPlayerValue> get notifier => _notifier;

  @override
  ValueListenable<Map<String, dynamic>>? get diagnostics => _diag;

  @override
  Future<List<AudioTrack>> getAudioTracks() async {
    final list = await _method.invokeMethod<List<dynamic>>('getAudioTracks');
    if (list == null) return [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return AudioTrack(
        id: m['id'] as String,
        label: m['label'] as String?,
        language: m['language'] as String?,
        codec: m['codec'] as String?,
        channels: (m['channels'] as num?)?.toInt(),
        isSelected: m['isSelected'] == true,
      );
    }).toList();
  }

  @override
  Future<void> selectAudioTrack(String id) =>
      _method.invokeMethod('selectAudioTrack', {'id': id});

  @override
  Future<void> setSurfaceBounds(Rect? rect, double dpr) async {
    if (rect == null) {
      await _method.invokeMethod('setSurfaceBounds', {'fullscreen': true});
    } else {
      await _method.invokeMethod('setSurfaceBounds', {
        'x': (rect.left * dpr).round(),
        'y': (rect.top * dpr).round(),
        'w': (rect.width * dpr).round(),
        'h': (rect.height * dpr).round(),
      });
    }
  }

  @override
  Future<void> initialize(String url) async {
    await _method.invokeMethod('setSurfaceShown', true);
    _sub ??= _events.receiveBroadcastStream().listen(_onEvent);
    await _method.invokeMethod('load', {
      'url': url,
      'profile': BufferProfile.forUrl(url).id,
    });
  }

  void _onEvent(dynamic e) {
    final m = Map<String, dynamic>.from(e as Map);
    final v = _notifier.value;
    switch (m['event']) {
      case 'initialized':
        _size = Size((m['width'] as num).toDouble(), (m['height'] as num).toDouble());
        _notifier.value = v.copyWith(isInitialized: true, size: _size);
        break;
      case 'videoSizeChanged':
        _size = Size((m['width'] as num).toDouble(), (m['height'] as num).toDouble());
        _notifier.value = v.copyWith(size: _size);
        break;
      case 'playing':
        _notifier.value = v.copyWith(isPlaying: true, isBuffering: false);
        break;
      case 'paused':
        _notifier.value = v.copyWith(isPlaying: false);
        break;
      case 'buffering':
        _notifier.value = v.copyWith(isBuffering: m['value'] as bool);
        break;
      case 'position':
        _notifier.value = v.copyWith(
          position: Duration(milliseconds: (m['ms'] as num).toInt()),
          duration: Duration(milliseconds: (m['duration'] as num).toInt()),
        );
        if (m['bufferedMs'] != null) {
          _diag.value = {..._diag.value, 'bufferedMs': m['bufferedMs']};
        }
        break;
      case 'stats':
        _diag.value = {..._diag.value, ...m}..remove('event');
        break;
      case 'error':
        _notifier.value = v.copyWith(
          hasError: true, errorDescription: '${m['code']}: ${m['msg']}');
        break;
      case 'audioDecoder':
        _diag.value = {
          ..._diag.value,
          'audioDecoder': m['name'],
          'ffmpeg': m['ffmpeg'] == true,
        };
        break;
    }
  }

  @override
  Future<void> play() => _method.invokeMethod('play');
  @override
  Future<void> pause() => _method.invokeMethod('pause');
  @override
  Future<void> seekTo(Duration position) =>
      _method.invokeMethod('seekTo', {'ms': position.inMilliseconds});

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _method.invokeMethod('setSurfaceShown', false);
    await _method.invokeMethod('release');
  }

  @override
  Widget buildView() => const SizedBox.expand();
}
