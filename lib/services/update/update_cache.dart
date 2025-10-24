import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存文件信息
class CachedFileInfo {
  final String filePath;
  final String version;
  final int fileSize;
  final DateTime modifiedTime;

  CachedFileInfo({
    required this.filePath,
    required this.version,
    required this.fileSize,
    required this.modifiedTime,
  });

  /// 格式化文件大小
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB';
    }
  }

  /// 格式化修改时间（相对时间）
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(modifiedTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

/// 更新缓存管理类
class UpdateCache {
  UpdateCache._();

  // 缓存相关常量
  static const String _cachedFilePathKey = 'cached_update_file_path';
  static const String _cachedVersionKey = 'cached_update_version';
  static const String _cachedTimestampKey = 'cached_update_timestamp';

  /// 缓存文件信息
  static Future<CachedFileInfo?> checkCachedFileInfoForUrl(
      String downloadUrl) async {
    try {
      // 从URL中提取版本信息
      final uri = Uri.parse(downloadUrl);
      final fileName = uri.pathSegments.last;
      print('[UpdateCache] 检查缓存文件，URL文件名: $fileName');

      // 获取下载目录
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = await getExternalStorageDirectory();
      }
      downloadDir ??= await getApplicationDocumentsDirectory();

      // 从URL文件名提取版本号
      String? version;
      final versionMatch =
          RegExp(r'xplayer-([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(fileName);
      if (versionMatch != null) {
        version = versionMatch.group(1);
        print('[UpdateCache] 从URL提取的版本号: $version');
      }

      if (version == null) {
        print('[UpdateCache] 无法从URL中提取版本号: $downloadUrl');
        return null;
      }

      // 在下载目录中查找对应版本的安装包
      final files = downloadDir.listSync();
      for (final checkFile in files) {
        if (checkFile is File &&
            checkFile.path.contains('xplayer') &&
            checkFile.path.contains(version)) {
          // 验证文件是否存在且可读
          if (await checkFile.exists()) {
            final fileSize = await checkFile.length();
            final fileStat = await checkFile.stat();
            print('[UpdateCache] 找到缓存文件: ${checkFile.path}, 大小: $fileSize字节');
            return CachedFileInfo(
              filePath: checkFile.path,
              version: version,
              fileSize: fileSize,
              modifiedTime: fileStat.modified,
            );
          }
        }
      }

      print('[UpdateCache] 未找到版本 $version 的缓存文件');
      return null;
    } catch (e) {
      print('[UpdateCache] 检查缓存文件失败: $e');
      return null;
    }
  }

  /// 检查是否有缓存的安装包对应给定的下载URL（简化版本，仅返回路径）
  static Future<String?> checkCachedFileForUrl(String downloadUrl) async {
    final info = await checkCachedFileInfoForUrl(downloadUrl);
    return info?.filePath;
  }

  /// 保存文件路径到缓存
  static Future<void> saveFilePath(String filePath, String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedFilePathKey, filePath);
      await prefs.setString(_cachedVersionKey, version);
      await prefs.setInt(
          _cachedTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('[UpdateCache] 已保存文件路径到缓存: $filePath');
    } catch (e) {
      print('[UpdateCache] 保存文件路径失败: $e');
    }
  }

  /// 获取缓存的文件路径
  static Future<String?> getCachedFilePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString(_cachedFilePathKey);

      if (cachedPath != null) {
        // 检查文件是否还存在
        final file = File(cachedPath);
        if (await file.exists()) {
          // 检查是否在7天内下载的（避免过期）
          final timestamp = prefs.getInt(_cachedTimestampKey) ?? 0;
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final daysSinceDownload =
              DateTime.now().difference(cachedTime).inDays;

          if (daysSinceDownload <= 7) {
            print('[UpdateCache] 找到有效的缓存文件: $cachedPath');
            return cachedPath;
          } else {
            print('[UpdateCache] 缓存文件已过期（$daysSinceDownload天），清理缓存');
            await clearCache();
          }
        } else {
          print('[UpdateCache] 缓存文件不存在，清理缓存');
          await clearCache();
        }
      }

      return null;
    } catch (e) {
      print('[UpdateCache] 获取缓存文件路径失败: $e');
      return null;
    }
  }

  /// 清理缓存
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString(_cachedFilePathKey);

      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
          print('[UpdateCache] 已删除缓存文件: $cachedPath');
        }
      }

      await prefs.remove(_cachedFilePathKey);
      await prefs.remove(_cachedVersionKey);
      await prefs.remove(_cachedTimestampKey);

      print('[UpdateCache] 已清理缓存');
    } catch (e) {
      print('[UpdateCache] 清理缓存失败: $e');
    }
  }
}
