import 'dart:async';

import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../data/journal_db.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/mood_picker.dart';
import '../widgets/surface_card.dart';

/// Writes the entry for [date]. Saves automatically as you type, and when the
/// app is backgrounded or the screen closes.
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.date,
    this.entryId,
    this.startNew = false,
    this.onNewEntry,
  });

  final String date;

  /// Open this specific entry. When null, the latest entry on [date] is used.
  final String? entryId;

  /// With no [entryId], start a blank entry instead of opening the latest one.
  final bool startNew;

  /// Shows a "new entry" button when set.
  final VoidCallback? onNewEntry;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _status = ValueNotifier<String>('');
  Timer? _debounce;
  Entry? _entry;
  int? _mood;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _save(); // Not awaited. It reads the text before the controllers go away.
    _title.dispose();
    _body.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _save();
  }

  Future<void> _load() async {
    final Entry? entry;
    if (widget.entryId != null) {
      entry = await JournalDb.instance.byId(widget.entryId!);
    } else if (widget.startNew) {
      entry = null;
    } else {
      entry = await JournalDb.instance.latestOnDate(widget.date);
    }
    if (!mounted) return;
    _entry = entry;
    _title.text = entry?.title ?? '';
    _body.text = entry?.body ?? '';
    _mood = entry?.mood;
    setState(() => _loaded = true);
  }

  void _setMood(int? mood) {
    setState(() => _mood = mood);
    _onChanged('');
  }

  void _onChanged(String _) {
    _status.value = '';
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    _debounce?.cancel();

    // Read everything before the first await.
    final title = _title.text;
    final body = _body.text;
    final mood = _mood;
    final current = _entry;

    final isBlank = title.trim().isEmpty && body.trim().isEmpty && mood == null;
    if (current == null && isBlank) return; // Don't create empty entries.
    if (current != null &&
        current.title == title &&
        current.body == body &&
        current.mood == mood) {
      return; // Nothing changed.
    }

    final saved = (current ?? Entry.blank(widget.date)).edited(
      title: title,
      body: body,
      mood: mood,
    );
    _entry = saved; // Set now so an overlapping save reuses the same id.

    try {
      await JournalDb.instance.save(saved);
      if (mounted) {
        _status.value = 'Saved';
        if (current == null)
          setState(() {}); // Now there is something to delete.
      }
    } catch (_) {
      _entry = current;
      if (mounted) _status.value = 'Could not save';
    }
  }

  Future<void> _confirmDelete() async {
    final entry = _entry;
    if (entry == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Empty the editor first, so saving on close can't write the entry back.
    _debounce?.cancel();
    _entry = null;
    _title.clear();
    _body.clear();
    _mood = null;

    await JournalDb.instance.delete(entry.id);
    messenger.showSnackBar(const SnackBar(content: Text('Entry deleted')));

    if (navigator.canPop()) {
      navigator.pop();
    } else if (mounted) {
      await _load(); // Back to today's other entry, or a blank page.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = entryTextStyle(context);

    return Scaffold(
      body: SafeArea(
        child: !_loaded
            ? const SizedBox.shrink()
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      children: [
                        _Header(
                          date: widget.date,
                          status: _status,
                          onNewEntry: widget.onNewEntry,
                          onDelete: _entry == null ? null : _confirmDelete,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            MoodPicker(value: _mood, onChanged: _setMood),
                            if (_mood != null)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    moodLabel(_mood!),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: colors.muted),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SurfaceCard(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _title,
                                  onChanged: _onChanged,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: style.copyWith(
                                    fontSize: 22,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Title (optional)',
                                    hintStyle: style.copyWith(
                                      fontSize: 22,
                                      height: 1.4,
                                      color: colors.muted,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                                const Divider(),
                                Expanded(
                                  child: TextField(
                                    controller: _body,
                                    onChanged: _onChanged,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    keyboardType: TextInputType.multiline,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: style,
                                    decoration: InputDecoration(
                                      hintText: 'Write something…',
                                      hintStyle: style.copyWith(
                                        color: colors.muted,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    required this.status,
    this.onNewEntry,
    this.onDelete,
  });

  final String date;
  final ValueNotifier<String> status;
  final VoidCallback? onNewEntry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Past entries are opened from the list, so they get a way back.
        if (Navigator.of(context).canPop())
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weekdayName(date), style: serif(context, 32)),
              Text(
                longDate(date),
                style: TextStyle(color: colors.muted, fontSize: 15),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: status,
          builder: (context, value, _) =>
              Text(value, style: TextStyle(color: colors.muted, fontSize: 13)),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Delete entry',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        if (onNewEntry != null)
          IconButton(
            tooltip: 'New entry',
            icon: const Icon(Icons.add),
            onPressed: onNewEntry,
          ),
      ],
    );
  }
}
