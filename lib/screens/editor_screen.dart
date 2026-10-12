import 'dart:async';

import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../data/journal_db.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/surface_card.dart';

/// Writes the entry for [date]. Saves automatically as you type, and when the
/// app is backgrounded or the screen closes.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.date});

  final String date;

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
    final entry = await JournalDb.instance.byDate(widget.date);
    if (!mounted) return;
    _entry = entry;
    _title.text = entry?.title ?? '';
    _body.text = entry?.body ?? '';
    setState(() => _loaded = true);
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
    final current = _entry;

    final isBlank = title.trim().isEmpty && body.trim().isEmpty;
    if (current == null && isBlank) return; // Don't create empty entries.
    if (current != null && current.title == title && current.body == body) {
      return; // Nothing changed.
    }

    final saved = (current ?? Entry.blank(widget.date)).edited(
      title: title,
      body: body,
    );
    _entry = saved; // Set now so an overlapping save reuses the same id.

    try {
      await JournalDb.instance.save(saved);
      if (mounted) _status.value = 'Saved';
    } catch (_) {
      _entry = current;
      if (mounted) _status.value = 'Could not save';
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
                        _Header(date: widget.date, status: _status),
                        const SizedBox(height: 16),
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
  const _Header({required this.date, required this.status});

  final String date;
  final ValueNotifier<String> status;

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
      ],
    );
  }
}
