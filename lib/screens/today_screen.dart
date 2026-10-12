import 'package:flutter/material.dart';

import '../util/dates.dart';
import 'editor_screen.dart';

/// Home screen: always the editor for today's date, even if the app stays
/// open past midnight.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver {
  String _date = todayKey();

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
      setState(() => _date = todayKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditorScreen(key: ValueKey(_date), date: _date);
  }
}
