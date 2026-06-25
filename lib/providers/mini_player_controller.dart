import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect, Size, EdgeInsets;
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/services/player/x_player_backend.dart';

enum PlayerMode { none, fullscreen, mini }

/// 小窗几何(overlay 布局与原生 SurfaceView 矩形共用,避免两处漂移)。
const double kMiniMargin = 12; // 距屏幕右/下边距
const double kMiniHeader = 26; // 顶部操作条高(放 X/展开,露出在视频之上)

/// 小窗卡片整体矩形(右下角)。
Rect miniCardRect(Size screen, EdgeInsets padding) {
  final w = (screen.width * 0.4).clamp(160.0, 240.0);
  final h = w * 9 / 16 + kMiniHeader; // 视频 16:9 + 顶部操作条
  final left = screen.width - w - kMiniMargin - padding.right;
  final top = screen.height - h - kMiniMargin - padding.bottom;
  return Rect.fromLTWH(left, top, w, h);
}

/// 卡片去掉顶部操作条后的视频子矩形(原生 SurfaceView 置顶渲染于此)。
Rect miniVideoRect(Size screen, EdgeInsets padding) {
  final c = miniCardRect(screen, padding);
  return Rect.fromLTWH(c.left, c.top + kMiniHeader, c.width, c.height - kMiniHeader);
}

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
