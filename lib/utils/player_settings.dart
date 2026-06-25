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

/// 首页「最近播放」模块显示开关(默认开;关闭只影响显示,不停止记录)。
final ValueNotifier<bool> showRecentModule = ValueNotifier<bool>(true);

const String _kShowRecentKey = 'home_show_recent';

Future<void> loadRecentModuleSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    showRecentModule.value = prefs.getBool(_kShowRecentKey) ?? true;
  } catch (_) {}
}

Future<void> setShowRecentModule(bool v) async {
  showRecentModule.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowRecentKey, v);
  } catch (_) {}
}

/// 首页「收藏」行显示开关(默认开)。
final ValueNotifier<bool> showFavoritesRow = ValueNotifier<bool>(true);

const String _kShowFavRowKey = 'home_show_favorites_row';

Future<void> loadFavoritesRowSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    showFavoritesRow.value = prefs.getBool(_kShowFavRowKey) ?? true;
  } catch (_) {}
}

Future<void> setShowFavoritesRow(bool v) async {
  showFavoritesRow.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowFavRowKey, v);
  } catch (_) {}
}

/// 返回首页后小窗续播(默认开)。
final ValueNotifier<bool> miniPlayerOnExit = ValueNotifier<bool>(true);
const String _kMiniOnExitKey = 'mini_player_on_exit';
Future<void> loadMiniPlayerSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    miniPlayerOnExit.value = prefs.getBool(_kMiniOnExitKey) ?? true;
  } catch (_) {}
}
Future<void> setMiniPlayerOnExit(bool v) async {
  miniPlayerOnExit.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMiniOnExitKey, v);
  } catch (_) {}
}

/// 回桌面系统画中画(仅 Android;默认开)。
final ValueNotifier<bool> pipOnLeave = ValueNotifier<bool>(true);
const String _kPipOnLeaveKey = 'pip_on_leave';
Future<void> loadPipSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    pipOnLeave.value = prefs.getBool(_kPipOnLeaveKey) ?? true;
  } catch (_) {}
}
Future<void> setPipOnLeave(bool v) async {
  pipOnLeave.value = v;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPipOnLeaveKey, v);
  } catch (_) {}
}
