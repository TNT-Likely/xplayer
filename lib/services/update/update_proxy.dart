import 'package:shared_preferences/shared_preferences.dart';

/// 在线更新下载使用的 HTTP 代理（`host:port`）。
///
/// **仅作用于 APK / 安装包下载**（国内 GitHub 下载慢），不影响直播流播放、EPG 等。
class UpdateProxy {
  UpdateProxy._();

  static const String prefKey = 'update_proxy';

  /// 读取已保存的代理（`host:port`）；未设置返回 null。
  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(prefKey)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// 保存代理；传空字符串/ null 则清除（恢复直连）。
  static Future<void> set(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      await prefs.remove(prefKey);
    } else {
      await prefs.setString(prefKey, v);
    }
  }
}
