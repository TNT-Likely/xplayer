import 'package:shared_preferences/shared_preferences.dart';

/// 在线更新下载使用的 HTTP 代理（`host:port`）。
///
/// **仅作用于 APK / 安装包下载**（国内 GitHub 下载慢），不影响直播流播放、EPG 等。
class UpdateProxy {
  UpdateProxy._();

  static const String prefKey = 'update_proxy';

  /// 归一化用户输入为 `host:port`:去掉 http(s):// 等 scheme 前缀、首尾空白
  /// 与末尾路径/斜杠。HttpClient.findProxy 的 `PROXY host:port` 指令不接受
  /// scheme,因此带 `http://`/`https://` 必须先剥掉,否则代理不生效。
  static String? normalize(String? raw) {
    var v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    // 去掉任意 scheme://(http://、https://、socks5:// 等)
    v = v.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://'), '');
    // 只保留 host:port,丢弃后面的路径
    final slash = v.indexOf('/');
    if (slash >= 0) v = v.substring(0, slash);
    v = v.trim();
    return v.isEmpty ? null : v;
  }

  /// 读取已保存的代理（`host:port`）；未设置返回 null。
  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return normalize(prefs.getString(prefKey));
  }

  /// 保存代理；传空字符串/ null 则清除（恢复直连）。带 http(s):// 也兼容。
  static Future<void> set(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = normalize(value);
    if (v == null) {
      await prefs.remove(prefKey);
    } else {
      await prefs.setString(prefKey, v);
    }
  }
}
