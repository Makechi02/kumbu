import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'entry.dart';

/// The only place that talks to SQLite.
class JournalDb {
  JournalDb._();

  static final JournalDb instance = JournalDb._();

  static const _createTable = '''
    CREATE TABLE entries (
      id         TEXT PRIMARY KEY,
      entry_date TEXT NOT NULL,
      title      TEXT NOT NULL DEFAULT '',
      body       TEXT NOT NULL DEFAULT '',
      mood       INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const _createIndex =
      'CREATE INDEX entries_date_idx ON entries (entry_date, created_at)';

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'journal.db');
    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(_createTable);
        await db.execute(_createIndex);
      },
    );
    await _allowSeveralEntriesPerDay(db);
    return db;
  }

  /// The first version made entry_date UNIQUE, so a second entry on a day
  /// replaced the first. SQLite can only drop a constraint by rebuilding the
  /// table. This checks the real schema on every open instead of trusting the
  /// database version, and does nothing when the table is already fine.
  Future<void> _allowSeveralEntriesPerDay(Database db) async {
    if (!await _hasUniqueDate(db)) return;

    await db.transaction((txn) async {
      await txn.execute('ALTER TABLE entries RENAME TO entries_old');
      await txn.execute(_createTable);
      await txn.execute('''
        INSERT INTO entries
          (id, entry_date, title, body, mood, created_at, updated_at)
        SELECT id, entry_date, title, body, mood, created_at, updated_at
        FROM entries_old
      ''');
      await txn.execute('DROP TABLE entries_old');
      await txn.execute(_createIndex);
    });
  }

  Future<bool> _hasUniqueDate(Database db) async {
    final indexes = await db.rawQuery('PRAGMA index_list(entries)');
    for (final index in indexes) {
      if (index['unique'] != 1) continue;
      final columns = await db.rawQuery(
        "PRAGMA index_info('${index['name']}')",
      );
      if (columns.any((c) => c['name'] == 'entry_date')) return true;
    }
    return false;
  }

  Future<Entry?> byId(String id) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Entry.fromMap(rows.first);
  }

  /// The most recently created entry on [date], if any.
  Future<Entry?> latestOnDate(String date) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      where: 'entry_date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
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

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
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
    const order = 'entry_date DESC, created_at DESC';

    final rows = q.isEmpty
        ? await db.query('entries', orderBy: order)
        : await db.query(
            'entries',
            where: r"title LIKE ? ESCAPE '\' OR body LIKE ? ESCAPE '\'",
            whereArgs: [_likePattern(q), _likePattern(q)],
            orderBy: order,
          );

    return rows.map(Entry.fromMap).toList();
  }

  /// Entries on [date], oldest first.
  Future<List<Entry>> onDate(String date) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      where: 'entry_date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return rows.map(Entry.fromMap).toList();
  }

  /// How many entries each day has between [from] and [to], both inclusive.
  Future<Map<String, int>> entryCounts(String from, String to) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT entry_date, COUNT(*) AS n FROM entries '
      'WHERE entry_date >= ? AND entry_date <= ? GROUP BY entry_date',
      [from, to],
    );
    return {for (final r in rows) r['entry_date'] as String: r['n'] as int};
  }

  /// The mood for each day since [fromDate]. When a day has several entries
  /// with a mood, the latest one wins.
  Future<Map<String, int>> moodsByDay(String fromDate) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      columns: ['entry_date', 'mood'],
      where: 'mood IS NOT NULL AND entry_date >= ?',
      whereArgs: [fromDate],
      orderBy: 'created_at ASC',
    );
    return {for (final r in rows) r['entry_date'] as String: r['mood'] as int};
  }

  String _likePattern(String q) {
    final escaped = q
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return '%$escaped%';
  }
}
