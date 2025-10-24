// lib/data/repositories/playlist_repository.dart

import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xml/xml.dart';
import 'package:m3u_parser_nullsafe/m3u_parser_nullsafe.dart';
import 'dart:convert';
import 'package:xplayer/extensions/m3u.dart';
import 'package:xplayer/data/repositories/channels_file_storage.dart';
import 'package:xplayer/data/repositories/playlist_database_recovery.dart';

class PlaylistRepository {
  static final PlaylistRepository _instance = PlaylistRepository._internal();
  factory PlaylistRepository() => _instance;
  PlaylistRepository._internal();

  Database? _database;
  final _fileStorage = ChannelsFileStorage();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'playlists-2.db');

    // 在打开数据库前，检查是否需要迁移并创建备份
    final dbFile = File(path);
    if (await dbFile.exists()) {
      try {
        // 检查当前数据库版本
        final tempDb = await openDatabase(path, readOnly: true);
        final version = await tempDb.getVersion();
        await tempDb.close();

        if (version < 2) {
          print('检测到数据库需要升级 (v$version -> v2)，创建备份...');
          await PlaylistDatabaseRecovery.createBackup();
        }
      } catch (e) {
        print('检查数据库版本时出错: $e');
      }
    }

    return await openDatabase(
      path,
      version: 2, // 升级到版本2，将channels迁移到文件存储
      onCreate: (db, version) async {
        // 新安装直接创建不含channels字段的表
        await db.execute('''
          CREATE TABLE Playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            epgUrl TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        print('✓ 新数据库已创建（版本2）');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 从版本1升级到版本2：将channels从数据库迁移到文件
          await _migrateChannelsToFiles(db);
        }
      },
    );
  }

  /// 数据迁移：将channels从数据库迁移到文件存储
  Future<void> _migrateChannelsToFiles(Database db) async {
    try {
      print('开始数据迁移：版本1 -> 版本2');

      // 1. 先获取所有playlist的ID（不读取大字段）
      final List<Map<String, dynamic>> idList = await db.rawQuery(
        'SELECT id FROM Playlists'
      );
      print('找到 ${idList.length} 个播放列表需要迁移');

      // 2. 逐个读取channels数据并保存到文件（避免一次性加载所有大数据）
      int migratedCount = 0;
      for (final item in idList) {
        final id = item['id'] as int;

        try {
          // 单独查询每个playlist的channels字段
          final result = await db.rawQuery(
            'SELECT channels FROM Playlists WHERE id = ? LIMIT 1',
            [id]
          );

          if (result.isNotEmpty) {
            final channels = result[0]['channels'] as String?;
            if (channels != null && channels.isNotEmpty) {
              await _fileStorage.saveChannels(id, channels);
              migratedCount++;
              print('已迁移 playlist #$id 的 channels 数据 (${(channels.length / 1024).toStringAsFixed(1)} KB)');
            }
          }
        } catch (e) {
          // 如果某个playlist的channels太大，记录错误但继续处理其他的
          print('⚠ 警告: 无法迁移 playlist #$id 的 channels: $e');
        }
      }
      print('成功迁移 $migratedCount 个播放列表的 channels 数据到文件');

      // 3. 重建表（SQLite不支持DROP COLUMN，需要重建表）
      await db.execute('''
        CREATE TABLE Playlists_new (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          url TEXT NOT NULL,
          epgUrl TEXT,
          created_at TIMESTAMP,
          updated_at TIMESTAMP
        )
      ''');
      print('创建新表结构完成');

      // 4. 复制数据（不包括channels字段），保留原有id
      await db.execute('''
        INSERT INTO Playlists_new (id, name, url, epgUrl, created_at, updated_at)
        SELECT id, name, url, epgUrl, created_at, updated_at FROM Playlists
      ''');
      print('数据复制到新表完成');

      // 5. 删除旧表
      await db.execute('DROP TABLE Playlists');
      print('删除旧表完成');

      // 6. 重命名新表
      await db.execute('ALTER TABLE Playlists_new RENAME TO Playlists');
      print('✓ 数据迁移完成：channels已从数据库迁移到文件存储');
    } catch (e, stackTrace) {
      print('✗ 数据迁移失败: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

// 插入新的播放列表
  Future<Playlist> insertPlaylist(Playlist playlist) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert(
        'Playlists',
        {
          'name': playlist.name,
          'url': playlist.url,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    return Playlist(name: playlist.name, url: playlist.url, id: id);
  }

// 更新现有的播放列表
  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'Playlists',
      {
        'name': playlist.name,
        'url': playlist.url,
        'epgUrl': playlist.epgUrl,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  // 删除播放列表
  Future<int> deletePlaylist(int id) async {
    final db = await database;

    // 同时删除channels文件
    await _fileStorage.deleteChannels(id);

    return await db.delete(
      'Playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有播放列表（不加载 channels 字段，避免数据过大）
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    // 只查询必要的列，排除 channels 字段（可能很大）
    final List<Map<String, dynamic>> maps = await db.query(
      'Playlists',
      columns: ['id', 'name', 'url', 'epgUrl', 'created_at', 'updated_at'],
    );
    return List.generate(maps.length, (i) {
      return Playlist.fromMap(maps[i]);
    });
  }

// 根据 ID 获取播放列表（不加载 channels 字段，避免数据过大）
  Future<Playlist?> getPlaylistById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Playlists',
      columns: ['id', 'name', 'url', 'epgUrl', 'created_at', 'updated_at'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }

    return null;
  }

  /// 获取播放列表的channels数据（从文件存储读取）
  Future<String?> getPlaylistChannels(int playlistId) async {
    return await _fileStorage.loadChannels(playlistId);
  }

  /// 保存播放列表的channels数据（到文件存储）
  Future<void> savePlaylistChannels(int playlistId, String channelsJson) async {
    await _fileStorage.saveChannels(playlistId, channelsJson);
  }

  /// 从给定的URL下载M3U文件并解析它。
  Future<M3uList> loadM3UFromUrl(String url) async {
    final uri = Uri.tryParse(url);

    try {
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final httpClient = HttpClient();
        httpClient.connectionTimeout = const Duration(seconds: 30);

        // 企业内网证书处理（Zscaler等代理证书）
        httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

        try {
          final request = await httpClient.getUrl(uri);
          final response = await request.close();

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final m3uList = M3uList.load(responseBody);
            httpClient.close();
            return m3uList;
          } else {
            httpClient.close();
            throw Exception(
                'Failed to load M3U file, status code: ${response.statusCode}');
          }
        } finally {
          httpClient.close();
        }
      } else {
        // 处理本地文件
        final String filePath =
            (uri != null && uri.scheme == 'file') ? uri.toFilePath() : url;
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Local M3U file not found: $filePath');
        }
        final bytes = await file.readAsBytes();
        final m3uContent = utf8.decode(bytes);
        return M3uList.load(m3uContent);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 根据播放列表ID更新播放列表的JSON内容。
  Future<M3uList> updatePlaylistWithM3uById(int playlistId, String url) async {
    final playlist = await getPlaylistById(playlistId);

    // 下载并解析M3U文件
    final m3uList = await loadM3UFromUrl(url);

    // 提取 EPG URL，如果不存在则使用空字符串
    String epgUrl = '';
    if (m3uList.header?.attributes != null &&
        m3uList.header!.attributes.isNotEmpty) {
      epgUrl = m3uList.header!.attributes['x-tvg-url'] ?? '';
    }

    // 将 M3uList 转换为 JSON 字符串
    final channels = m3uList.toChannels();
    final channelsJson = jsonEncode(channels);

    if (playlist != null) {
      final newPlaylist = playlist.copyWith(epgUrl: epgUrl);

      // 更新数据库中的播放列表记录（不包含channels）
      await updatePlaylist(newPlaylist);

      // 将channels保存到文件存储
      await savePlaylistChannels(playlistId, channelsJson);
    }

    return m3uList;
  }

  Future<List<Programme>> fetchAndParseEpgData(String url) async {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 30);

    // 企业内网证书处理
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    try {
      final uri = Uri.parse(url);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final document = XmlDocument.parse(body);
        final programmes = <Programme>[];

        for (final element in document.findAllElements('programme')) {
          programmes.add(Programme.fromXmlElement(element));
        }

        return programmes;
      } else {
        throw Exception('Failed to load EPG data, status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  // 获取所有播放列表的节目单并返回合并后的 List<Programme>
  Future<List<Programme>> fetchAllPlaylistsProgrammes() async {
    try {
      final playlists = await getAllPlaylists();

      // 并发地获取每个播放列表的 EPG 数据
      final futures = playlists.map((playlist) async {
        try {
          final programmes = await fetchAndParseEpgData(playlist.epgUrl!);
          return programmes;
        } catch (e) {
          return <Programme>[]; // 返回空列表，表示该 URL 的数据获取失败
        }
      }).toList();

      // 等待所有 Future 完成，合并所有成功的节目单
      final results = await Future.wait(futures);

      // 将所有成功的节目单合并成一个列表
      final allProgrammes = results.expand((element) => element).toList();

      return allProgrammes;
    } catch (e) {
      return []; // 如果发生全局错误，返回空列表
    }
  }
}
