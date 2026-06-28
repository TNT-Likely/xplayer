import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:xplayer/services/cast/dlna_device.dart';
import 'package:xplayer/services/cast/dlna_discovery.dart';
import 'package:xplayer/services/cast/dlna_controller.dart';

enum CastState { idle, discovering, connecting, casting, error }

/// 投屏状态机:发现 DLNA 设备、投出、远端控制与状态轮询。
class CastProvider with ChangeNotifier {
  final DlnaDiscovery _discovery = DlnaDiscovery();

  CastState _state = CastState.idle;
  CastState get state => _state;

  List<DlnaDevice> _devices = [];
  List<DlnaDevice> get devices => List.unmodifiable(_devices);

  DlnaDevice? _current;
  DlnaDevice? get current => _current;
  bool get isCasting => _current != null;

  String? _transport; // PLAYING / PAUSED_PLAYBACK / STOPPED ...
  String? get transport => _transport;
  Duration _position = Duration.zero;
  Duration get position => _position;

  String? _error;
  String? get error => _error;

  DlnaController? _ctrl;
  Timer? _poll;

  /// 扫描局域网 DLNA 设备。
  Future<void> refresh() async {
    if (_state == CastState.discovering) return;
    _state = CastState.discovering;
    _error = null;
    notifyListeners();
    try {
      _devices = await _discovery.search();
    } catch (e) {
      _error = '$e';
    }
    _state = isCasting ? CastState.casting : CastState.idle;
    notifyListeners();
  }

  /// 把某地址投到设备。成功开始状态轮询。
  Future<bool> castTo(DlnaDevice device,
      {required String url, required String title}) async {
    _state = CastState.connecting;
    _error = null;
    notifyListeners();

    final ctrl = DlnaController(device);
    final ok = await ctrl.setUriAndPlay(url, title: title);
    if (!ok) {
      _state = CastState.error;
      _error = '该设备未能播放此源(可能不支持该格式/直播)';
      notifyListeners();
      return false;
    }
    _ctrl = ctrl;
    _current = device;
    _transport = 'PLAYING';
    _position = Duration.zero;
    _state = CastState.casting;
    notifyListeners();
    _startPolling();
    return true;
  }

  Future<void> pause() async {
    await _ctrl?.pause();
    _transport = 'PAUSED_PLAYBACK';
    notifyListeners();
  }

  Future<void> play() async {
    await _ctrl?.play();
    _transport = 'PLAYING';
    notifyListeners();
  }

  /// 停止投屏(通知设备 Stop 并清理本地状态)。返回投屏时的最后进度,供手机续播。
  Future<Duration> stopCast() async {
    final pos = _position;
    _poll?.cancel();
    _poll = null;
    await _ctrl?.stop();
    _ctrl = null;
    _current = null;
    _transport = null;
    _position = Duration.zero;
    _state = CastState.idle;
    notifyListeners();
    return pos;
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      final c = _ctrl;
      if (c == null) return;
      final st = await c.transportState();
      final pos = await c.position();
      if (_ctrl == null) return; // 轮询期间已停止
      if (st != null) _transport = st;
      if (pos != null) _position = pos;
      // 远端自然结束 → 退出投屏态
      if (st == 'STOPPED' || st == 'NO_MEDIA_PRESENT') {
        _poll?.cancel();
        _poll = null;
        _ctrl = null;
        _current = null;
        _transport = null;
        _state = CastState.idle;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
