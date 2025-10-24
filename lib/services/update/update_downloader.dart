import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'update_result.dart';
import 'update_cache.dart';

/// 更新下载管理类
class UpdateDownloader {
  UpdateDownloader._();

  static final Dio _dio = Dio();

  /// 生成随机User-Agent
  static String _generateRandomUserAgent() {
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
    ];
    final random = (DateTime.now().millisecondsSinceEpoch % userAgents.length);
    return userAgents[random];
  }

  /// 下载安装包
  static Future<UpdateResult> downloadFile(
    BuildContext context,
    String url,
    String fileName, {
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 获取下载目录
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = await getExternalStorageDirectory();
      }
      downloadDir ??= await getApplicationDocumentsDirectory();

      // 确定文件扩展名
      String ext = '.apk';
      if (url.endsWith('.dmg')) {
        ext = '.dmg';
      } else if (url.endsWith('.zip')) {
        ext = '.zip';
      } else if (url.endsWith('.tar.gz')) {
        ext = '.tar.gz';
      }

      final filePath = '${downloadDir.path}/xplayer_$fileName$ext';
      print('[UpdateDownloader] 下载路径: $filePath');

      // 删除旧文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 显示下载进度对话框
      double progress = 0.0;
      bool cancelled = false;
      late StateSetter dialogSetState;

      // 创建取消令牌
      final cancelToken = CancelToken();

      if (context.mounted) {
        final localizations = AppLocalizations.of(context)!;
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              dialogSetState = setState;
              final progressPercent = (progress * 100).toStringAsFixed(1);
              return AlertDialog(
                backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
                title: Text(
                  localizations.downloadingUpdate,
                  style: const TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.downloading(progressPercent),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
                actionsOverflowButtonSpacing: 8,
                actions: [
                  XTextButton(
                    text: localizations.cancel,
                    size: XTextButtonSize.flexible,
                    onPressed: () {
                      cancelled = true;
                      cancelToken.cancel('User cancelled');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  XTextButton(
                    text: localizations.downloadInBackground,
                    size: XTextButtonSize.flexible,
                    type: XTextButtonType.primary,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ),
        );
      }

      // 开始下载
      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'User-Agent': _generateRandomUserAgent(),
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && !cancelled) {
            final newProgress = received / total;
            progress = newProgress;
            final progressPercent = (progress * 100).round();

            // 调用外部进度回调
            onProgress?.call(newProgress, '下载中: $progressPercent%');

            // 更新UI进度
            try {
              dialogSetState(() {});
            } catch (e) {
              // 对话框已关闭，忽略错误
            }
          }
        },
        cancelToken: cancelToken,
      );

      if (cancelled) {
        print('[UpdateDownloader] 用户取消下载');
        onProgress?.call(0.0, '');
        return UpdateResult.userCancelled();
      }

      // 下载完成，关闭对话框
      if (context.mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          print('[UpdateDownloader] 关闭对话框失败: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      print('[UpdateDownloader] 下载完成: $filePath');

      // 保存到缓存
      final versionMatch = RegExp(r'([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(fileName);
      if (versionMatch != null) {
        await UpdateCache.saveFilePath(filePath, versionMatch.group(1)!);
      }

      onProgress?.call(1.0, '下载完成');
      return UpdateResult.downloadSuccess(filePath);
    } catch (e) {
      // 检查是否是用户取消
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print('[UpdateDownloader] 用户取消下载');
        onProgress?.call(0.0, '');
        return UpdateResult.userCancelled();
      }

      print('[UpdateDownloader] 下载失败: $e');

      // 关闭对话框
      if (context.mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          // ignore
        }
      }

      onProgress?.call(0.0, '');
      return UpdateResult.downloadFailed('$e');
    }
  }
}
