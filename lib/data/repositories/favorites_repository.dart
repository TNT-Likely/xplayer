import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:xplayer/data/models/channel_model.dart'; // 确保路径正确

class FavoritesRepository {
  static final FavoritesRepository _instance = FavoritesRepository._internal();
  factory FavoritesRepository() => _instance;
  FavoritesRepository._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'favorites-2.db');
    return await openDatabase(
      path,
      version: 1, // 增加版本号以支持新表结构
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        logo TEXT,
        source TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
      )
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> addFavorite(Channel channel) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': channel.id,
        'name': channel.name,
        'logo': channel.logo,
        'source': jsonEncode(channel.source.map((s) => s.toJson()).toList()),
        'created_at': channel.createdAt?.toIso8601String(),
        'updated_at': channel.updatedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Channel>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');

    return maps.map((map) {
      final List<Source> sources =
          List.from(jsonDecode(map['source'] as String))
              .map((item) => Source.fromJson(item))
              .toList();

      return Channel(
        id: map['id'],
        name: map['name'],
        logo: map['logo'],
        source: sources,
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );
    }).toList();
  }

  Future<bool> isFavorite(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );

    return maps.isNotEmpty;
  }

  Future<void> updateFavorite(Channel channel) async {
    final db = await database;
    await db.update(
      'favorites',
      {
        'name': channel.name,
        'logo': channel.logo,
        'source': jsonEncode(channel.source.map((s) => s.toJson()).toList()),
        'updated_at': channel.updatedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [channel.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
