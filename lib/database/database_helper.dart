import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hour_log.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE time_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            check_in INTEGER NOT NULL,
            check_out INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertRecord(TimeRecord record) async {
    final db = await database;
    return db.insert('time_records', record.toMap());
  }

  Future<int> updateRecord(TimeRecord record) async {
    final db = await database;
    return db.update(
      'time_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<TimeRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('time_records', orderBy: 'check_in DESC');
    return maps.map(TimeRecord.fromMap).toList();
  }

  Future<TimeRecord?> getActiveRecord() async {
    final db = await database;
    final maps = await db.query(
      'time_records',
      where: 'check_out IS NULL',
      orderBy: 'check_in DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TimeRecord.fromMap(maps.first);
  }

  Future<List<TimeRecord>> getRecordsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'time_records',
      where: 'check_in >= ? AND check_in < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'check_in DESC',
    );
    return maps.map(TimeRecord.fromMap).toList();
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('time_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedSampleData() async {
    final existing = await getAllRecords();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final sampleRecords = <TimeRecord>[
      TimeRecord(
        checkIn: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          9,
          0,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          17,
          0,
        ).millisecondsSinceEpoch,
      ),
      TimeRecord(
        checkIn: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          9,
          20,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          17,
          10,
        ).millisecondsSinceEpoch,
      ),
      TimeRecord(
        checkIn: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          8,
          45,
        ).millisecondsSinceEpoch,
        checkOut: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          16,
          50,
        ).millisecondsSinceEpoch,
      ),
    ];

    if (now.weekday <= 5) {
      sampleRecords.add(
        TimeRecord(
          checkIn: DateTime(now.year, now.month, now.day, 10, 0)
              .millisecondsSinceEpoch,
          checkOut: null,
        ),
      );
    }

    for (final record in sampleRecords) {
      await insertRecord(record);
    }
  }
}
