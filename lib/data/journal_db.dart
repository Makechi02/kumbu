import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'entry.dart';

/// The only place that talks to SQLite.
class JournalDb {
  JournalDb._();

  static final JournalDb instance = JournalDb._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'journal.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE entries (
          id         TEXT PRIMARY KEY,
          entry_date TEXT NOT NULL UNIQUE,
          title      TEXT NOT NULL DEFAULT '',
          body       TEXT NOT NULL DEFAULT '',
          mood       INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      '''),
    );
  }

  Future<Entry?> byDate(String date) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      where: 'entry_date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : Entry.fromMap(rows.first);
  }

  /// Insert or replace by id.
  Future<void> save(Entry entry) async {
    final db = await _database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> count() async {
    final db = await _database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM entries'),
        ) ??
        0;
  }

  /// Newest first. A non-empty [query] matches the title or body.
  Future<List<Entry>> list({String query = ''}) async {
    final db = await _database;
    final q = query.trim();

    final rows = q.isEmpty
        ? await db.query('entries', orderBy: 'entry_date DESC')
        : await db.query(
            'entries',
            where: r"title LIKE ? ESCAPE '\' OR body LIKE ? ESCAPE '\'",
            whereArgs: [_likePattern(q), _likePattern(q)],
            orderBy: 'entry_date DESC',
          );

    return rows.map(Entry.fromMap).toList();
  }

  String _likePattern(String q) {
    final escaped =
        q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    return '%$escaped%';
  }
}
