// lib/data/repositories/playlist_repository.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:m3u_parser_nullsafe/m3u_parser_nullsafe.dart';
import 'dart:convert';
import 'package:xplayer/extensions/m3u.dart';

class PlaylistRepository {
  static final PlaylistRepository _instance = PlaylistRepository._internal();
  factory PlaylistRepository() => _instance;
  PlaylistRepository._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'playlists-2.db');

    return await openDatabase(path, version: 1, // 增加版本号以便进行迁移
        onCreate: (db, version) async {
      await db.execute('''
            CREATE TABLE Playlists (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              url TEXT NOT NULL,
              channels TEXT, 
              epgUrl TEXT,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      // 根据旧版本和新版本之间的差异执行不同的迁移逻辑
      // if (oldVersion < 3) {
      //   // 如果是从版本2升级到版本3，则添加programmes_json字段
      //   await db.execute('''
      //         ALTER TABLE Playlists ADD COLUMN programmes_json TEXT;
      //       ''');
      // }
    });
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
          'channels': playlist.channels,
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
        'channels': playlist.channels,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  // 删除播放列表
  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete(
      'Playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有播放列表
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Playlists');
    return List.generate(maps.length, (i) {
      return Playlist.fromMap(maps[i]);
    });
  }

// 根据 ID 获取播放列表
  Future<Playlist?> getPlaylistById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Playlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }

    return null;
  }

  /// 从给定的URL下载M3U文件并解析它。
  Future<M3uList> loadM3UFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // 解析M3U内容
      final m3uContent = utf8.decode(response.bodyBytes);
      final m3uList = M3uList.load(m3uContent);
      return m3uList;
    } else {
      throw Exception(
          'Failed to load M3U file, status code: ${response.statusCode}');
    }
  }

  /// 根据播放列表ID更新播放列表的JSON内容。
  Future<M3uList> updatePlaylistWithM3uById(int playlistId, String url) async {
    final playlist = await getPlaylistById(playlistId);

    // 下载并解析M3U文件
    final m3uList = await loadM3UFromUrl(url);

    late String epgUrl;
    // 如果你还想检查 attributes 是否为空，可以在前面添加条件判断
    if (m3uList.header?.attributes != null &&
        m3uList.header!.attributes.isNotEmpty) {
      epgUrl = m3uList.header!.attributes['x-tvg-url'] ?? '';
    }

    // 将 M3uList 转换为 JSON 字符串
    final channels = m3uList.toChannels();

    if (playlist != null) {
      final newPlaylist = playlist.copyWith(
        epgUrl: epgUrl,
        channels: jsonEncode(channels),
      );

      // 更新数据库中的播放列表记录
      await updatePlaylist(newPlaylist);
    }

    return m3uList;
  }

  Future<List<Programme>> fetchAndParseEpgData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String body = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(body);
        final programmes = <Programme>[];

        for (final element in document.findAllElements('programme')) {
          programmes.add(Programme.fromXmlElement(element));
        }

        return programmes;
      } else {
        throw Exception('Failed to load EPG data');
      }
    } catch (e) {
      print('Error fetching and parsing EPG data: $e');
      rethrow;
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
          print(
              'Fetched ${programmes.length} programmes for playlist ${playlist.name}');
          return programmes;
        } catch (e) {
          print('Failed to fetch programmes for playlist ${playlist.name}: $e');
          return <Programme>[]; // 返回空列表，表示该 URL 的数据获取失败
        }
      }).toList();

      // 等待所有 Future 完成，合并所有成功的节目单
      final results = await Future.wait(futures);

      // 将所有成功的节目单合并成一个列表
      final allProgrammes = results.expand((element) => element).toList();

      return allProgrammes;
    } catch (e) {
      print('An error occurred while processing all playlists: $e');
      return []; // 如果发生全局错误，返回空列表
    }
  }
}
