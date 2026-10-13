import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../data/journal_db.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/entry_card.dart';
import '../widgets/mood_strip.dart';
import 'editor_screen.dart';

/// All entries, newest first, grouped by month, with search.
class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final _search = TextEditingController();
  List<Entry> _entries = const [];
  List<int?> _moods = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final rows = await JournalDb.instance.list(query: _search.text);
    final moods = await _recentMoods();
    if (!mounted) return;
    setState(() {
      _entries = rows;
      _moods = moods;
    });
  }

  /// One value per day for the last 30 days, oldest first. Null means no mood.
  Future<List<int?>> _recentMoods() async {
    final now = DateTime.now();
    DateTime day(int i) => DateTime(now.year, now.month, now.day - 29 + i);

    final byDay = await JournalDb.instance.moodsByDay(dateKey(day(0)));
    return [for (var i = 0; i < 30; i++) byDay[dateKey(day(i))]];
  }

  Future<void> _open(Entry entry) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(date: entry.entryDate, entryId: entry.id),
      ),
    );
    await _reload();
  }

  /// Entries with a month heading (a String) before each new month.
  List<Object> _withMonthHeadings() {
    final items = <Object>[];
    String? month;
    for (final e in _entries) {
      final label = monthLabel(e.entryDate);
      if (label != month) {
        items.add(label);
        month = label;
      }
      items.add(e);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = _withMonthHeadings();
    if (items.isNotEmpty && _search.text.trim().isEmpty) {
      items.insert(0, _StripItem(_moods));
    }

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Entries', style: serif(context, 32)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Search entries',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: border(colors.line),
                  enabledBorder: border(colors.line),
                  focusedBorder: border(colors.accent),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        _search.text.trim().isEmpty
                            ? 'No entries yet. Write your first one today.'
                            : 'No entries match your search.',
                        style: TextStyle(color: colors.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        if (item is _StripItem) {
                          return MoodStrip(moods: item.moods);
                        }
                        if (item is String) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: colors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return EntryCard(
                          entry: item as Entry,
                          onTap: () => _open(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks where the mood strip goes in the list.
class _StripItem {
  const _StripItem(this.moods);

  final List<int?> moods;
}
