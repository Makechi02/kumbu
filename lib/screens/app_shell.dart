import 'package:flutter/material.dart';

import '../data/backup_service.dart';
import 'backup_screen.dart';
import 'calendar_screen.dart';
import 'entries_screen.dart';
import 'today_screen.dart';

/// The three tabs. Only the selected tab is built, so every visit loads fresh
/// data and leaving the editor saves it.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _screens = [
    TodayScreen(),
    CalendarScreen(),
    EntriesScreen(),
    BackupScreen(),
  ];

  int _index = 0;
  bool _backupDue = false;

  @override
  void initState() {
    super.initState();
    _refreshBackupBadge();
  }

  Future<void> _refreshBackupBadge() async {
    final due = await BackupService().isBackupDue();
    if (!mounted) return;
    setState(() => _backupDue = due);
  }

  void _select(int index) {
    setState(() => _index = index);
    _refreshBackupBadge();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // Each tab handles the keyboard itself.
      resizeToAvoidBottomInset: false,
      body: _screens[_index],
      // Hidden while typing so the keyboard gets the room.
      bottomNavigationBar: keyboardOpen
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.edit_outlined),
                  selectedIcon: Icon(Icons.edit),
                  label: 'Write',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Entries',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _backupDue,
                    child: const Icon(Icons.archive_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _backupDue,
                    child: const Icon(Icons.archive),
                  ),
                  label: 'Backup',
                ),
              ],
            ),
    );
  }
}
