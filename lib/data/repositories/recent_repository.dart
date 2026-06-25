import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/utils/recent_util.dart';

class RecentRepository {
  static final RecentRepository _instance = RecentRepository._internal();
  factory RecentRepository() => _instance;
  RecentRepository._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'recent.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recent (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        logo TEXT,
        source TEXT NOT NULL,
        played_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> addRecent(Channel channel) async {
    final db = await database;
    await db.insert(
      'recent',
      {
        'id': channel.id,
        'name': channel.name,
        'logo': channel.logo,
        'source': jsonEncode(channel.source.map((s) => s.toJson()).toList()),
        'played_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.rawDelete(
      'DELETE FROM recent WHERE id NOT IN '
      '(SELECT id FROM recent ORDER BY played_at DESC LIMIT ?)',
      [kRecentMax],
    );
  }

  Future<List<Channel>> getRecent() async {
    final db = await database;
    final maps = await db.query('recent', orderBy: 'played_at DESC');
    return maps.map((map) {
      final sources = List.from(jsonDecode(map['source'] as String))
          .map((item) => Source.fromJson(item))
          .toList();
      return Channel(
        id: map['id'] as String,
        name: map['name'] as String,
        logo: map['logo'] as String?,
        source: sources,
      );
    }).toList();
  }

  Future<void> removeRecent(String id) async {
    final db = await database;
    await db.delete('recent', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearRecent() async {
    final db = await database;
    await db.delete('recent');
  }
}
