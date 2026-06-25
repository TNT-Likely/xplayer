import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放渲染模式:
/// - true  = SurfaceView(video_player 的 platformView,Hybrid Composition 真 SurfaceView,
///           解码输出直接进显示合成器,吃电视硬件 VPP/锐化 → 电视上更清晰,对齐 TVMate/StreamVault);
/// - false = 纹理(textureView,走 Flutter GPU 纹理,兼容性最好,但绕开硬件 VPP)。
/// 默认纹理(textureView):实测这台电视上 SurfaceView(platformView/Hybrid Composition)
/// 既拿不到硬件 VPP(不变清晰)又更卡/一直缓冲(合成开销 + 视频被 Flutter 合成、没走显示叠加层)。
/// SurfaceView 作为可选项保留(想试再开),不当默认。切换后播放器按新模式重建。
final ValueNotifier<bool> useSurfaceView = ValueNotifier<bool>(false);

const String _kRenderKey = 'player_use_surface_view';

Future<void> loadRenderMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    useSurfaceView.value = prefs.getBool(_kRenderKey) ?? false;
  } catch (_) {}
}

Future<void> setUseSurfaceView(bool v) async {
  useSurfaceView.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRenderKey, v);
  } catch (_) {}
}

/// 播放引擎:true = 原生 Android 引擎(SurfaceView,吃硬件 VPP);false = video_player。
/// Android 默认 true;出错运行时自动降级到 video_player(见 player.dart)。
final ValueNotifier<bool> useNativeEngine = ValueNotifier<bool>(true);

const String _kNativeEngineKey = 'player_use_native_engine';

Future<void> loadNativeEngineMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    useNativeEngine.value = prefs.getBool(_kNativeEngineKey) ?? true;
  } catch (_) {}
}

Future<void> setUseNativeEngine(bool v) async {
  useNativeEngine.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNativeEngineKey, v);
  } catch (_) {}
}
