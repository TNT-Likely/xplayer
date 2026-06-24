import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放渲染模式:
/// - true  = SurfaceView(video_player 的 platformView,Hybrid Composition 真 SurfaceView,
///           解码输出直接进显示合成器,吃电视硬件 VPP/锐化 → 电视上更清晰,对齐 TVMate/StreamVault);
/// - false = 纹理(textureView,走 Flutter GPU 纹理,兼容性最好,但绕开硬件 VPP)。
/// 默认 SurfaceView。切换后播放器按新模式重建。
final ValueNotifier<bool> useSurfaceView = ValueNotifier<bool>(true);

const String _kRenderKey = 'player_use_surface_view';

Future<void> loadRenderMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    useSurfaceView.value = prefs.getBool(_kRenderKey) ?? true;
  } catch (_) {}
}

Future<void> setUseSurfaceView(bool v) async {
  useSurfaceView.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRenderKey, v);
  } catch (_) {}
}
