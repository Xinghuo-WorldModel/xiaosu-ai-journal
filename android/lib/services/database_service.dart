import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'xiaosu_diary.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diaries(
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            mood TEXT NOT NULL,
            keywords TEXT,
            source TEXT NOT NULL,
            conversations TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_date ON diaries(date)');
      },
    );
  }

  static Future<void> saveDiary(DiaryEntry entry) async {
    final db = await database;
    await db.insert(
      'diaries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<DiaryEntry?> getDiary(String id) async {
    final db = await database;
    final maps = await db.query('diaries', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  static Future<DiaryEntry?> getDiaryByDate(String date) async {
    final db = await database;
    final maps = await db.query('diaries', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  static Future<List<DiaryEntry>> getAllDiaries() async {
    final db = await database;
    final maps = await db.query('diaries', orderBy: 'createdAt DESC');
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  static Future<void> deleteDiary(String id) async {
    final db = await database;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<DiaryEntry>> searchDiaries(String keyword) async {
    final db = await database;
    final lower = keyword.toLowerCase();
    final maps = await db.query(
      'diaries',
      where: 'LOWER(content) LIKE ? OR LOWER(keywords) LIKE ? OR LOWER(mood) LIKE ?',
      whereArgs: ['%$lower%', '%$lower%', '%$lower%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }
}
