import 'dart:io' show Platform;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 稳定且可区分的设备名(用于广播服务名 / ConfigBundle.deviceName)。
/// `Platform.localHostname` 在很多设备上返回 "localhost",两端会撞名,
/// 故附加一次性持久化的短 id。
Future<String> syncDeviceName() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('sync_device_id');
  if (id == null || id.isEmpty) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    id = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    await prefs.setString('sync_device_id', id);
  }
  var host = Platform.localHostname;
  if (host.isEmpty || host.toLowerCase() == 'localhost') {
    host = Platform.operatingSystem; // android / ios / macos …
  }
  return 'XPlayer-$host-$id';
}
