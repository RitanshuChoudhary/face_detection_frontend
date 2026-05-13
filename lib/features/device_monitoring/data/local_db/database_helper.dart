import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sqflite.Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<sqflite.Database> _initDb() async {
    String path = join(await sqflite.getDatabasesPath(), 'monitoring_data.db');
    return await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(sqflite.Database db, int version) async {
    // Table for SMS and Notifications
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT, -- 'SMS', 'WHATSAPP', 'NOTIFICATION'
        sender TEXT,
        content TEXT,
        timestamp TEXT,
        package_name TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Table for Call Logs
    await db.execute('''
      CREATE TABLE calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        type TEXT, -- 'INCOMING', 'OUTGOING', 'MISSED'
        duration TEXT,
        timestamp TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertLog(Map<String, dynamic> row) async {
    sqflite.Database db = await database;
    return await db.insert('logs', row);
  }

  Future<int> insertCall(Map<String, dynamic> row) async {
    sqflite.Database db = await database;
    return await db.insert('calls', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    sqflite.Database db = await database;
    return await db.query('logs', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<int> markLogSynced(int id) async {
    sqflite.Database db = await database;
    return await db.update('logs', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
