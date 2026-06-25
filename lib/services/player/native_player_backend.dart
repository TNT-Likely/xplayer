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

  @override
  ValueListenable<XPlayerValue> get notifier => _notifier;

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
        break;
      case 'error':
        _notifier.value = v.copyWith(
          hasError: true, errorDescription: '${m['code']}: ${m['msg']}');
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
