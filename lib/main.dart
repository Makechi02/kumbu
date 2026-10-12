import 'package:flutter/material.dart';

import 'lock/lock_gate.dart';
import 'screens/app_shell.dart';
import 'theme.dart';

void main() => runApp(const JournalApp());

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kumbu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // The lock sits above the Navigator, so it covers every screen.
      builder: (context, child) => LockGate(child: child!),
      home: const AppShell(),
    );
  }
}