import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'update/update_result.dart';
import 'update/update_checker.dart';
import 'update/update_cache.dart';
import 'update/update_downloader.dart';
import 'update/update_installer.dart';
import 'update/update_permissions.dart';

/// 应用更新服务
class UpdateService {
  UpdateService._();

  /// 检查更新信息
  static Future<UpdateResult> checkUpdate() async {
    return UpdateChecker.checkUpdate();
  }

  /// 下载并安装更新（Android平台）
  static Future<UpdateResult> downloadAndInstall(
    BuildContext context,
    String downloadUrl, {
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 检查权限
      onProgress?.call(0.0, '检查权限...');
      final hasPermission = await UpdatePermissions.checkAndRequestPermissions();
      if (!hasPermission) {
        // 权限被拒绝，询问用户是否打开设置
        if (context.mounted) {
          final shouldOpenSettings = await _showPermissionDeniedDialog(context);
          if (shouldOpenSettings) {
            await UpdatePermissions.openSettings();
          }
        }
        return UpdateResult.permissionDenied();
      }

      // 检查缓存
      onProgress?.call(0.0, '检查缓存...');
      final cachedFileInfo = await UpdateCache.checkCachedFileInfoForUrl(downloadUrl);

      if (cachedFileInfo != null && context.mounted) {
        // 发现缓存文件，询问是否使用
        final useCache = await _showCachedFileDialog(context, cachedFileInfo);
        if (useCache == true) {
          // 安装缓存文件
          final installed = await UpdateInstaller.installApk(cachedFileInfo.filePath);
          return UpdateResult(
            hasUpdate: true,
            success: installed,
            message: installed ? '正在安装缓存版本' : '安装失败',
            filePath: cachedFileInfo.filePath,
          );
        } else if (useCache == null) {
          // 用户取消
          return UpdateResult.userCancelled();
        }
        // useCache == false 表示用户选择重新下载，继续执行后续下载逻辑
      }

      // 下载文件
      onProgress?.call(0.0, '准备下载...');
      final uri = Uri.parse(downloadUrl);
      final fileName = uri.pathSegments.last;
      final versionMatch = RegExp(r'([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(fileName);
      final version = versionMatch?.group(1) ?? 'latest';

      final downloadResult = await UpdateDownloader.downloadFile(
        context,
        downloadUrl,
        version,
        onProgress: onProgress,
      );

      if (!downloadResult.success || downloadResult.filePath == null) {
        return downloadResult;
      }

      // 下载成功，询问是否立即安装
      if (context.mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          final shouldInstall = await UpdateInstaller.showInstallDialog(context);

          if (shouldInstall) {
            onProgress?.call(0.95, '启动安装程序...');
            await Future.delayed(const Duration(milliseconds: 300));

            final installed = await UpdateInstaller.installApk(downloadResult.filePath!);

            if (installed) {
              onProgress?.call(1.0, '安装程序已启动');
              return UpdateResult(
                hasUpdate: true,
                success: true,
                message: '安装程序已启动',
                filePath: downloadResult.filePath,
              );
            } else {
              return UpdateResult.installFailed('启动安装程序失败');
            }
          } else {
            // 用户选择稍后安装
            return UpdateResult(
              hasUpdate: true,
              success: true,
              message: '下载完成，可稍后手动安装',
              filePath: downloadResult.filePath,
            );
          }
        }
      }

      return downloadResult;
    } catch (e) {
      print('[UpdateService] 下载更新失败: $e');
      onProgress?.call(0.0, '');
      return UpdateResult.downloadFailed('$e');
    }
  }

  /// 显示权限被拒绝对话框
  static Future<bool> _showPermissionDeniedDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
          title: Text(
            localizations.permissionDenied,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            localizations.permissionDeniedMessage,
            style: const TextStyle(color: Colors.white),
          ),
          actionsOverflowButtonSpacing: 8,
          actions: [
            XTextButton(
              text: localizations.cancel,
              size: XTextButtonSize.flexible,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            XTextButton(
              text: localizations.goToSettings,
              size: XTextButtonSize.flexible,
              type: XTextButtonType.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// 显示缓存文件对话框
  static Future<bool?> _showCachedFileDialog(
    BuildContext context,
    CachedFileInfo cacheInfo,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
          title: Text(
            localizations.cachedVersionFound,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.cachedVersionMessage,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(localizations.version, 'v${cacheInfo.version}'),
              const SizedBox(height: 8),
              _buildInfoRow(localizations.size, cacheInfo.formattedSize),
              const SizedBox(height: 8),
              _buildInfoRow(localizations.downloadTime, cacheInfo.formattedTime),
              const SizedBox(height: 12),
              Text(
                localizations.useCachedVersion,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          actions: [
            XTextButton(
              text: localizations.cancel,
              size: XTextButtonSize.flexible,
              onPressed: () => Navigator.of(context).pop(null),
            ),
            const SizedBox(width: 8),
            XTextButton(
              text: localizations.redownload,
              size: XTextButtonSize.flexible,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            XTextButton(
              text: localizations.useCache,
              size: XTextButtonSize.flexible,
              type: XTextButtonType.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  /// 构建信息行
  static Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 完整的更新检查流程，包含UI交互
  static Future<void> checkUpdateWithUI(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    // 显示检查中提示
    showToast(localizations.checkingUpdate);

    try {
      final checkResult = await checkUpdate();

      if (!context.mounted) return;

      if (!checkResult.hasUpdate) {
        // 没有更新
        showToast(checkResult.message ?? localizations.alreadyLatestVersion);
        return;
      }

      // 发现有新版本，显示确认对话框
      final shouldDownload = await _showUpdateDialog(
        context,
        version: checkResult.version ?? 'unknown',
        releaseNotes: checkResult.releaseNotes ?? '',
        downloadUrl: checkResult.downloadUrl ?? '',
      );

      if (!shouldDownload || !context.mounted) {
        return;
      }

      // Android平台：本地下载并安装
      if (Platform.isAndroid) {
        final result = await downloadAndInstall(
          context,
          checkResult.downloadUrl!,
          onProgress: (progress, status) {
            // 可以在这里更新UI显示进度
            print('[UpdateService] Progress: ${(progress * 100).toInt()}% - $status');
          },
        );

        if (context.mounted && !result.success && result.message != null) {
          if (result.type != UpdateResultType.userCancelled) {
            showToast(result.message!);
          }
        }
      } else {
        // 其他平台：打开GitHub Release页面
        await _openReleasePageForCurrentPlatform();
      }
    } catch (e) {
      if (context.mounted) {
        final localizations = AppLocalizations.of(context)!;
        showToast(localizations.checkUpdateFailed(e.toString()));
      }
    }
  }

  /// 显示更新对话框
  static Future<bool> _showUpdateDialog(
    BuildContext context, {
    required String version,
    required String releaseNotes,
    required String downloadUrl,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
              title: Text(
                localizations.newVersionFound(version),
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.updateContent,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      releaseNotes.isNotEmpty ? releaseNotes : localizations.noReleaseNotes,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
                  text: localizations.updateNow,
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

  /// 根据当前平台打开对应的Release页面
  static Future<void> _openReleasePageForCurrentPlatform() async {
    const releasePageUrl = 'https://github.com/TNT-Likely/xplayer/releases/latest';

    try {
      final uri = Uri.parse(releasePageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (Platform.isWindows) {
          showToast('请在网页中下载Windows版本');
        } else if (Platform.isMacOS) {
          showToast('请在网页中下载macOS版本');
        } else if (Platform.isLinux) {
          showToast('请在网页中下载Linux版本');
        } else if (Platform.isIOS) {
          showToast('请在网页中下载iOS版本');
        }
      } else {
        showToast('无法打开Release页面');
      }
    } catch (e) {
      showToast('打开Release页面失败: $e');
    }
  }

  /// 获取缓存的安装包路径
  static Future<String?> getCachedFilePath() async {
    return UpdateCache.getCachedFilePath();
  }

  /// 清理缓存
  static Future<void> clearCache() async {
    return UpdateCache.clearCache();
  }
}
