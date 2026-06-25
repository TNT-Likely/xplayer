import 'package:flutter/foundation.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/services/player/x_player_backend.dart';

enum PlayerMode { none, fullscreen, mini }

/// 跨路由持有播放器 backend,实现返回首页后的小窗续播。
/// 「交接」模型:PlayerScreen 全屏时驱动 backend;返回时 enterMini 把 backend 交给本控制器
/// (不销毁);重开时 take() 取回。
class MiniPlayerController extends ChangeNotifier {
  XPlayerBackend? _backend;
  Channel? _channel;
  List<Channel> _favorites = const [];
  PlayerMode _mode = PlayerMode.none;

  XPlayerBackend? get backend => _backend;
  Channel? get channel => _channel;
  List<Channel> get favorites => _favorites;
  PlayerMode get mode => _mode;
  bool get hasMini => _mode == PlayerMode.mini && _backend != null;

  void attachFullscreen(
      XPlayerBackend backend, Channel channel, List<Channel> favorites) {
    _backend = backend;
    _channel = channel;
    _favorites = favorites;
    _mode = PlayerMode.fullscreen;
    notifyListeners();
  }

  void enterMini(
      XPlayerBackend backend, Channel channel, List<Channel> favorites) {
    _backend = backend;
    _channel = channel;
    _favorites = favorites;
    _mode = PlayerMode.mini;
    notifyListeners();
  }

  XPlayerBackend? take() {
    if (_backend == null) return null;
    _mode = PlayerMode.fullscreen;
    notifyListeners();
    return _backend;
  }

  Future<void> close() async {
    final b = _backend;
    _backend = null;
    _channel = null;
    _mode = PlayerMode.none;
    notifyListeners();
    await b?.pause();
    await b?.dispose();
  }

  void clearReference() {
    _backend = null;
    _channel = null;
    _mode = PlayerMode.none;
    notifyListeners();
  }
}
