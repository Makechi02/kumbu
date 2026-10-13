import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/dates.dart';
import 'entry.dart';
import 'journal_db.dart';

class ImportResult {
  const ImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  final int added;
  final int updated;
  final int skipped;
}

/// Export and import. The JSON backup is the one that can be restored.
class BackupService {
  static const _lastExportKey = 'last_json_export';
  static const _nudgeAfterDays = 14;
  static const _nudgeMinEntries = 3;

  /// Saves every entry as JSON. Returns false if the user cancelled.
  Future<bool> exportJson() async {
    final entries = await JournalDb.instance.list();
    final payload = {
      'app': 'kumbu',
      'format': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
    };
    final text = const JsonEncoder.withIndent('  ').convert(payload);

    final saved = await FilePicker.platform.saveFile(
      dialogTitle: 'Save backup',
      fileName: 'kumbu-${todayKey()}.json',
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
    if (saved == null) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastExportKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    return true;
  }

  /// Saves every entry as one readable Markdown file, oldest first.
  /// Returns false if the user cancelled. This file can't be imported.
  Future<bool> exportMarkdown() async {
    final entries = (await JournalDb.instance.list()).reversed;

    final out = StringBuffer('# Kumbu\n');
    for (final e in entries) {
      out.write('\n## ${prettyDate(e.entryDate)}, ${clockTime(e.createdAt)}\n');
      if (e.title.trim().isNotEmpty) out.write('\n### ${e.title.trim()}\n');
      out.write('\n${e.body.trim()}\n');
    }

    final saved = await FilePicker.platform.saveFile(
      dialogTitle: 'Save journal',
      fileName: 'kumbu-${todayKey()}.md',
      bytes: Uint8List.fromList(utf8.encode(out.toString())),
    );
    return saved != null;
  }

  /// Merges a JSON backup into the journal. For an entry that exists on both
  /// sides (same id), the one with the newer `updated_at` wins.
  /// Returns null if the user cancelled. Throws [FormatException] if the file
  /// isn't a Kumbu backup; nothing is imported in that case.
  Future<ImportResult?> importJson() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null) return null;

    final bytes = picked.files.single.bytes;
    if (bytes == null) throw const FormatException('Could not read the file');

    final incoming = _parse(bytes); // Parse everything first, then write.

    var added = 0;
    var updated = 0;
    var skipped = 0;
    for (final entry in incoming) {
      final existing = await JournalDb.instance.byId(entry.id);
      if (existing == null) {
        await JournalDb.instance.save(entry);
        added++;
      } else if (entry.updatedAt.isAfter(existing.updatedAt)) {
        await JournalDb.instance.save(entry);
        updated++;
      } else {
        skipped++;
      }
    }
    return ImportResult(added: added, updated: updated, skipped: skipped);
  }

  List<Entry> _parse(Uint8List bytes) {
    try {
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map || data['app'] != 'kumbu' || data['entries'] is! List) {
        throw const FormatException('Not a Kumbu backup');
      }
      return (data['entries'] as List).map((raw) {
        final entry = Entry.fromMap(Map<String, Object?>.from(raw as Map));
        DateTime.parse(entry.entryDate); // Rejects a malformed date.
        return entry;
      }).toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Not a Kumbu backup');
    }
  }

  Future<DateTime?> lastExport() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastExportKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  /// True when there are enough entries to matter and no recent JSON backup.
  Future<bool> isBackupDue() async {
    final count = await JournalDb.instance.count();
    if (count < _nudgeMinEntries) return false;

    final last = await lastExport();
    if (last == null) return true;

    return DateTime.now().difference(last).inDays >= _nudgeAfterDays;
  }
}
