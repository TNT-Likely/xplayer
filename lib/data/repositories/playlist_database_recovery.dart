// lib/data/repositories/playlist_database_recovery.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库恢复工具
/// 用于在迁移失败时恢复数据
class PlaylistDatabaseRecovery {
  /// 检查是否存在旧版本数据库备份
  static Future<bool> hasBackup() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final backupPath = join(documentsDirectory.path, 'playlists-2.db.backup');
    return await File(backupPath).exists();
  }

  /// 创建数据库备份（在迁移前调用）
  static Future<void> createBackup() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'playlists-2.db');
    final backupPath = join(documentsDirectory.path, 'playlists-2.db.backup');

    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
      print('✓ 数据库备份已创建: $backupPath');
    }
  }

  /// 从备份恢复数据库
  static Future<void> restoreFromBackup() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'playlists-2.db');
    final backupPath = join(documentsDirectory.path, 'playlists-2.db.backup');

    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.copy(dbPath);
      print('✓ 数据库已从备份恢复');
    } else {
      print('✗ 未找到备份文件');
    }
  }

  /// 检查数据库完整性
  static Future<bool> checkDatabaseIntegrity() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'playlists-2.db');

      final db = await openDatabase(dbPath, readOnly: true);
      final result = await db.rawQuery('PRAGMA integrity_check');
      await db.close();

      final isOk = result.isNotEmpty && result[0]['integrity_check'] == 'ok';
      print(isOk ? '✓ 数据库完整性检查通过' : '✗ 数据库完整性检查失败');
      return isOk;
    } catch (e) {
      print('✗ 数据库完整性检查失败: $e');
      return false;
    }
  }

  /// 获取数据库中的播放列表数量
  static Future<int> getPlaylistCount() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'playlists-2.db');

      final db = await openDatabase(dbPath, readOnly: true);
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM Playlists');
      await db.close();

      final count = result[0]['count'] as int;
      print('数据库中有 $count 个播放列表');
      return count;
    } catch (e) {
      print('✗ 查询播放列表数量失败: $e');
      return 0;
    }
  }

  /// 强制降级数据库版本（慎用）
  static Future<void> forceDowngrade() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'playlists-2.db');

    final db = await openDatabase(dbPath);
    await db.execute('PRAGMA user_version = 1');
    await db.close();
    print('✓ 数据库版本已降级到1');
  }
}
