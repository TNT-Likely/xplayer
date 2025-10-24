import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_result.dart';

/// 更新检查管理类
class UpdateChecker {
  UpdateChecker._();

  static final Dio _dio = Dio();

  /// 生成随机User-Agent，避免被GitHub限制
  static String _generateRandomUserAgent() {
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
    ];

    final random = (DateTime.now().millisecondsSinceEpoch % userAgents.length);
    return userAgents[random];
  }

  /// 检查更新信息
  static Future<UpdateResult> checkUpdate() async {
    try {
      // 获取当前版本信息
      final currentInfo = await _getAppInfo();
      final currentVersion = _normalizeVersion(currentInfo.version);

      print('[UpdateChecker] 当前版本: $currentVersion');

      // 配置Dio超时
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(minutes: 2);

      // 获取最新 release 信息 - 添加重试机制
      Response? resp;
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        attempts++;
        try {
          print('[UpdateChecker] 尝试第$attempts次请求GitHub API...');
          resp = await _dio.get(
            'https://api.github.com/repos/TNT-Likely/xplayer/releases/latest',
            options: Options(
              headers: {
                'Accept': 'application/vnd.github+json',
                'User-Agent': _generateRandomUserAgent(),
              },
            ),
          );
          if (resp.statusCode == 200) {
            print('[UpdateChecker] GitHub API请求成功');
            break;
          }
          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          print('[UpdateChecker] 第$attempts次请求失败: $e');
          if (attempts == maxAttempts) rethrow;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (resp != null && resp.statusCode == 200) {
        final data = resp.data;
        final latestVersion = _normalizeVersion(data['tag_name']);

        print('[UpdateChecker] 最新版本: $latestVersion');

        if (_isNewerVersion(latestVersion, currentVersion)) {
          // 找到对应平台的下载链接
          final assets = data['assets'] as List;
          String? downloadUrl;

          // 根据平台选择对应的安装包
          final String platformExt;
          if (Platform.isAndroid) {
            platformExt = '.apk';
          } else if (Platform.isWindows) {
            platformExt = '-windows-x64.zip';
          } else if (Platform.isMacOS) {
            platformExt = '-macos.dmg';
          } else if (Platform.isLinux) {
            platformExt = '-linux-x64.tar.gz';
          } else {
            return UpdateResult(
              hasUpdate: false,
              message: '当前平台不支持自动更新',
            );
          }

          for (final asset in assets) {
            final assetName = asset['name'].toString();
            if (assetName.endsWith(platformExt)) {
              downloadUrl = asset['browser_download_url'];
              break;
            }
          }

          if (downloadUrl != null) {
            return UpdateResult(
              hasUpdate: true,
              version: latestVersion,
              downloadUrl: downloadUrl,
              releaseNotes: data['body'] ?? '',
            );
          } else {
            return UpdateResult(
              hasUpdate: false,
              message: '未找到适合当前平台的安装包',
            );
          }
        } else {
          return UpdateResult.alreadyLatest(latestVersion);
        }
      } else {
        final statusCode = resp?.statusCode ?? 'unknown';
        return UpdateResult.checkFailed('HTTP $statusCode');
      }
    } catch (e) {
      print('[UpdateChecker] 检查更新异常: $e');
      return UpdateResult.checkFailed('$e');
    }
  }

  // 辅助方法
  static Future<AppInfo> _getAppInfo() async {
    final p = await PackageInfo.fromPlatform();
    return AppInfo(p.version, p.buildNumber);
  }

  static String _normalizeVersion(String version) {
    String normalized = version;
    if (normalized.startsWith('v')) {
      normalized = normalized.substring(1);
    }
    if (normalized.startsWith('dev-')) {
      normalized = normalized.substring(4);
    }
    final dashIndex = normalized.indexOf('-');
    if (dashIndex != -1) {
      normalized = normalized.substring(0, dashIndex);
    }
    return normalized;
  }

  static bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion
        .split('.')
        .map(int.tryParse)
        .where((e) => e != null)
        .cast<int>()
        .toList();
    final currentParts = currentVersion
        .split('.')
        .map(int.tryParse)
        .where((e) => e != null)
        .cast<int>()
        .toList();

    final maxLength =
        [newParts.length, currentParts.length].reduce((a, b) => a > b ? a : b);
    while (newParts.length < maxLength) {
      newParts.add(0);
    }
    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }

    return false;
  }
}
