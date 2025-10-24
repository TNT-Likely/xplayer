import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'update_permissions.dart';

/// 更新安装管理类
class UpdateInstaller {
  UpdateInstaller._();

  /// 安装APK（仅Android）
  static Future<bool> installApk(String filePath) async {
    try {
      print('[UpdateInstaller] 开始安装流程');
      print('[UpdateInstaller] 文件路径: $filePath');

      // 检查文件是否存在
      final file = File(filePath);
      final exists = await file.exists();
      print('[UpdateInstaller] 文件是否存在: $exists');

      if (!exists) {
        print('[UpdateInstaller] 文件不存在，无法安装');
        return false;
      }

      // 检查文件大小
      final fileSize = await file.length();
      print('[UpdateInstaller] 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // 检查权限
      final hasPermission = await UpdatePermissions.checkAndRequestPermissions();
      print('[UpdateInstaller] 权限状态: $hasPermission');

      if (!hasPermission) {
        return false;
      }

      // 打开安装程序
      final result = await OpenFilex.open(filePath);
      print('[UpdateInstaller] 安装结果: ${result.type}');
      print('[UpdateInstaller] 安装消息: ${result.message}');

      return result.type == ResultType.done;
    } catch (e) {
      print('[UpdateInstaller] 安装失败: $e');
      return false;
    }
  }

  /// 显示安装确认对话框
  static Future<bool> showInstallDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
              title: Text(
                localizations.installUpdate,
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(
                localizations.downloadComplete,
                style: const TextStyle(color: Colors.white),
              ),
              actionsOverflowButtonSpacing: 8,
              actions: [
                XTextButton(
                  text: localizations.later,
                  size: XTextButtonSize.flexible,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 8),
                XTextButton(
                  text: localizations.installNow,
                  size: XTextButtonSize.flexible,
                  type: XTextButtonType.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
