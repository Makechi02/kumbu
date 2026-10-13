import 'package:flutter/material.dart';

import '../util/dates.dart';
import 'editor_screen.dart';

/// Home screen: today's latest entry, with a button to start another.
/// Rolls over to the new date if the app stays open past midnight.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  String _date = todayKey();

  /// Bumped to start a fresh entry. The editor saves itself as it is replaced.
  int _session = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && todayKey() != _date) {
      setState(() {
        _date = todayKey();
        _session = 0;
      });
    }
  }

  void _newEntry() => setState(() => _session++);

  @override
  Widget build(BuildContext context) {
    return EditorScreen(
      key: ValueKey('$_date#$_session'),
      date: _date,
      startNew: _session > 0,
      onNewEntry: _newEntry,
    );
  }
}
