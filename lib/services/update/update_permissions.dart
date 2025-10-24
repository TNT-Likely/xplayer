import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 更新权限管理类
class UpdatePermissions {
  UpdatePermissions._();

  /// 检查和申请权限
  static Future<bool> checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;

    print('[UpdatePermissions] 开始检查权限...');

    // Android 10以下需要存储权限
    try {
      if (Platform.version.contains('API')) {
        final versionParts = Platform.version.split(' ');
        if (versionParts.isNotEmpty) {
          final apiLevel = int.tryParse(versionParts.last);
          if (apiLevel != null && apiLevel <= 29) {
            final storageStatus = await Permission.storage.status;
            print('[UpdatePermissions] 存储权限状态: $storageStatus');
            if (!storageStatus.isGranted) {
              final result = await Permission.storage.request();
              print('[UpdatePermissions] 存储权限申请结果: $result');
              if (!result.isGranted) {
                print('[UpdatePermissions] 存储权限被拒绝');
                if (result.isPermanentlyDenied) {
                  print('[UpdatePermissions] 存储权限被永久拒绝，需要打开设置页面');
                }
                return false;
              }
            }
          }
        }
      }
    } catch (e) {
      print('[UpdatePermissions] 检查存储权限失败: $e');
    }

    // 安装权限
    try {
      final installStatus = await Permission.requestInstallPackages.status;
      print('[UpdatePermissions] 安装权限状态: $installStatus');
      if (!installStatus.isGranted) {
        print('[UpdatePermissions] 尝试请求安装权限...');
        final result = await Permission.requestInstallPackages.request();
        print('[UpdatePermissions] 安装权限申请结果: $result');
        if (!result.isGranted) {
          print('[UpdatePermissions] 安装权限被拒绝');
          if (result.isPermanentlyDenied) {
            print('[UpdatePermissions] 安装权限被永久拒绝，需要打开设置页面');
          }
          return false;
        }
      }
    } catch (e) {
      print('[UpdatePermissions] 检查安装权限失败: $e');
      print('[UpdatePermissions] 错误详情: ${e.toString()}');
      return false;
    }

    print('[UpdatePermissions] 权限检查完成');
    return true;
  }

  /// 打开应用设置页面
  static Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('[UpdatePermissions] 打开设置页面失败: $e');
      return false;
    }
  }
}
