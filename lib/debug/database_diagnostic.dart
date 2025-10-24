// lib/debug/database_diagnostic.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库诊断工具
class DatabaseDiagnostic {
  static Future<void> runDiagnostic() async {
    print('========== 数据库诊断开始 ==========');

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'playlists-2.db');
    final backupPath = join(documentsDirectory.path, 'playlists-2.db.backup');

    // 1. 检查数据库文件是否存在
    final dbFile = File(dbPath);
    print('\n[1] 数据库文件');
    if (await dbFile.exists()) {
      final size = await dbFile.length();
      print('  ✓ 存在: $dbPath');
      print('  大小: ${(size / 1024).toStringAsFixed(2)} KB');
    } else {
      print('  ✗ 不存在: $dbPath');
    }

    // 2. 检查备份文件
    final backupFile = File(backupPath);
    print('\n[2] 备份文件');
    if (await backupFile.exists()) {
      final size = await backupFile.length();
      print('  ✓ 存在: $backupPath');
      print('  大小: ${(size / 1024).toStringAsFixed(2)} KB');
    } else {
      print('  ✗ 不存在: $backupPath');
    }

    if (!await dbFile.exists()) {
      print('\n========== 诊断结束 ==========');
      return;
    }

    try {
      // 3. 检查数据库版本
      final db = await openDatabase(dbPath, readOnly: true);
      final version = await db.getVersion();
      print('\n[3] 数据库版本: $version');

      // 4. 检查表结构
      print('\n[4] 表结构');
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'");
      for (final table in tables) {
        final tableName = table['name'] as String;
        print('  表: $tableName');

        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        for (final col in columns) {
          print('    - ${col['name']} (${col['type']})');
        }
      }

      // 5. 检查播放列表数量
      print('\n[5] 数据统计');
      try {
        final countResult =
            await db.rawQuery('SELECT COUNT(*) as count FROM Playlists');
        final count = countResult[0]['count'] as int;
        print('  播放列表数量: $count');

        if (count > 0) {
          // 获取ID列表
          final ids =
              await db.rawQuery('SELECT id, name FROM Playlists LIMIT 10');
          print('  前10个播放列表:');
          for (final item in ids) {
            print('    #${item['id']}: ${item['name']}');
          }
        }
      } catch (e) {
        print('  ✗ 查询失败: $e');
      }

      // 6. 检查channels文件
      print('\n[6] Channels文件存储');
      final channelsDir = Directory(join(documentsDirectory.path, 'channels'));
      if (await channelsDir.exists()) {
        final files = await channelsDir
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .toList();
        print('  ✓ 目录存在: ${channelsDir.path}');
        print('  文件数量: ${files.length}');

        for (final file in files.take(5)) {
          final size = await (file as File).length();
          final name = basename(file.path);
          print('    - $name: ${(size / 1024).toStringAsFixed(2)} KB');
        }
      } else {
        print('  ✗ 目录不存在: ${channelsDir.path}');
      }

      await db.close();
    } catch (e, stackTrace) {
      print('\n✗ 诊断过程中出错: $e');
      print('Stack trace: $stackTrace');
    }

    print('\n========== 诊断结束 ==========');
  }

  /// 尝试从备份恢复
  static Future<void> restoreFromBackup() async {
    print('========== 开始从备份恢复 ==========');

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'playlists-2.db');
    final backupPath = join(documentsDirectory.path, 'playlists-2.db.backup');

    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      print('✗ 备份文件不存在，无法恢复');
      return;
    }

    try {
      // 关闭当前数据库连接（如果有）
      // 删除当前数据库
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        print('✓ 已删除损坏的数据库');
      }

      // 复制备份
      await backupFile.copy(dbPath);
      print('✓ 已从备份恢复数据库');

      print('========== 恢复完成 ==========');
      print('请重启应用以使用恢复的数据库');
    } catch (e) {
      print('✗ 恢复失败: $e');
    }
  }
}
