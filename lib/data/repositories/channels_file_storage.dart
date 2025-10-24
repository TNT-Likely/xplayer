// lib/data/repositories/channels_file_storage.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// 管理播放列表频道数据的文件存储
/// 将channels从数据库迁移到独立文件，避免SQLite CursorWindow 2MB限制
class ChannelsFileStorage {
  static final ChannelsFileStorage _instance = ChannelsFileStorage._internal();
  factory ChannelsFileStorage() => _instance;
  ChannelsFileStorage._internal();

  /// 获取channels存储目录
  Future<Directory> _getChannelsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final channelsDir = Directory(join(documentsDirectory.path, 'channels'));
    if (!await channelsDir.exists()) {
      await channelsDir.create(recursive: true);
    }
    return channelsDir;
  }

  /// 获取指定playlist的channels文件路径
  Future<File> _getChannelsFile(int playlistId) async {
    final dir = await _getChannelsDirectory();
    return File(join(dir.path, 'playlist_$playlistId.json'));
  }

  /// 保存channels数据到文件
  /// [playlistId] 播放列表ID
  /// [channelsJson] channels的JSON字符串
  Future<void> saveChannels(int playlistId, String channelsJson) async {
    final file = await _getChannelsFile(playlistId);
    await file.writeAsString(channelsJson, flush: true);
  }

  /// 读取channels数据
  /// [playlistId] 播放列表ID
  /// 返回channels的JSON字符串，如果文件不存在返回null
  Future<String?> loadChannels(int playlistId) async {
    final file = await _getChannelsFile(playlistId);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// 删除指定playlist的channels文件
  /// [playlistId] 播放列表ID
  Future<void> deleteChannels(int playlistId) async {
    final file = await _getChannelsFile(playlistId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 检查channels文件是否存在
  /// [playlistId] 播放列表ID
  Future<bool> channelsExists(int playlistId) async {
    final file = await _getChannelsFile(playlistId);
    return await file.exists();
  }

  /// 获取channels文件大小（字节）
  /// [playlistId] 播放列表ID
  Future<int?> getChannelsFileSize(int playlistId) async {
    final file = await _getChannelsFile(playlistId);
    if (await file.exists()) {
      return await file.length();
    }
    return null;
  }

  /// 清空所有channels文件（慎用）
  Future<void> clearAllChannels() async {
    final dir = await _getChannelsDirectory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }
  }
}
