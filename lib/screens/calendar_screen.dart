import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../data/journal_db.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/entry_card.dart';
import '../widgets/surface_card.dart';
import 'editor_screen.dart';

/// A month grid. The selected day's entries are listed underneath, and you can
/// add an entry for that day.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = _firstOfMonth(DateTime.now());
  String _selected = todayKey();
  Map<String, int> _counts = const {};
  List<Entry> _dayEntries = const [];

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final month = _month;
    final selected = _selected;

    final counts = await JournalDb.instance.entryCounts(
      dateKey(month),
      dateKey(DateTime(month.year, month.month + 1, 0)),
    );
    final entries = await JournalDb.instance.onDate(selected);

    // Ignore the result if the user has moved on while it loaded.
    if (!mounted || month != _month || selected != _selected) return;
    setState(() {
      _counts = counts;
      _dayEntries = entries;
    });
  }

  void _select(String date) {
    setState(() => _selected = date);
    _reload();
  }

  void _changeMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    setState(() {
      _month = month;
      _selected = isCurrent ? todayKey() : dateKey(month);
    });
    _reload();
  }

  void _goToToday() {
    setState(() {
      _month = _firstOfMonth(DateTime.now());
      _selected = todayKey();
    });
    _reload();
  }

  /// Opens an existing [entry], or a blank one for the selected day.
  Future<void> _openEditor({Entry? entry}) async {
    final navigator = Navigator.of(context);
    final date = _selected;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => entry == null
            ? EditorScreen(date: date, startNew: true)
            : EditorScreen(date: entry.entryDate, entryId: entry.id),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isFuture = _selected.compareTo(todayKey()) > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        monthLabel(dateKey(_month)),
                        style: serif(context, 30),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Today',
                  icon: const Icon(Icons.today_outlined),
                  onPressed: _goToToday,
                ),
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: const EdgeInsets.all(12),
              child: _MonthGrid(
                month: _month,
                selected: _selected,
                counts: _counts,
                onSelect: _select,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekdayName(_selected), style: serif(context, 22)),
                        Text(
                          longDate(_selected),
                          style: TextStyle(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isFuture)
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add entry'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (isFuture)
              Text(
                'This day has not happened yet.',
                style: TextStyle(color: colors.muted),
              )
            else if (_dayEntries.isEmpty)
              Text(
                'No entries for this day.',
                style: TextStyle(color: colors.muted),
              )
            else
              for (final entry in _dayEntries)
                EntryCard(
                  entry: entry,
                  showDate: false,
                  onTap: () => _openEditor(entry: entry),
                ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final DateTime month;
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  // Weeks start on Sunday.
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = todayKey();
    // DateTime.weekday runs Monday = 1 to Sunday = 7, so % 7 puts Sunday at 0.
    final offset = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final d in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: _cell(r * 7 + c - offset + 1, daysInMonth, today),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth, String today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 48);

    final key = dateKey(DateTime(month.year, month.month, day));
    return _DayCell(
      day: day,
      selected: key == selected,
      isToday: key == today,
      isFuture: key.compareTo(today) > 0,
      hasEntries: (counts[key] ?? 0) > 0,
      onTap: () => onSelect(key),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.isFuture,
    required this.hasEntries,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool isToday;
  final bool isFuture;
  final bool hasEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = selected
        ? colors.accentInk
        : (isFuture ? colors.muted : colors.ink);
    final dotColor = !hasEntries
        ? Colors.transparent
        : (selected ? colors.accentInk : colors.accent);

    return SizedBox(
      height: 48,
      child: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? colors.accent : null,
              border: isToday && !selected
                  ? Border.all(color: colors.accent, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isToday || selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
