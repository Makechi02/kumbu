import 'package:flutter/material.dart';

import '../data/backup_service.dart';
import '../theme.dart';
import '../widgets/surface_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backup = BackupService();
  bool _busy = false;
  bool _due = false;
  DateTime? _lastExport;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final last = await _backup.lastExport();
    final due = await _backup.isBackupDue();
    if (!mounted) return;
    setState(() {
      _lastExport = last;
      _due = due;
    });
  }

  String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }

  /// Runs [action], which returns the message to show, or null if cancelled.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    String? message;
    try {
      message = await action();
    } on FormatException {
      message = "That file isn't a Kumbu backup.";
    } catch (_) {
      message = 'Something went wrong. Try again.';
    }

    if (!mounted) return;
    setState(() => _busy = false);
    await _refresh();
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final last = _lastExport;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Backup', style: serif(context, 32)),
            const SizedBox(height: 4),
            Text(
              last == null ? 'No backup yet.' : 'Last backup ${_ago(last)}.',
              style: TextStyle(color: colors.muted, fontSize: 15),
            ),
            if (_due) ...[
              const SizedBox(height: 16),
              _Nudge(
                text: last == null
                    ? 'Your entries only exist on this phone. Export a backup to keep them safe.'
                    : 'It has been a while. Export a fresh backup.',
              ),
            ],
            const SizedBox(height: 20),
            _ActionCard(
              icon: Icons.file_download_outlined,
              title: 'Export backup',
              subtitle: 'Everything, as a file you can import later.',
              onTap: _busy
                  ? null
                  : () => _run(() async =>
              await _backup.exportJson() ? 'Backup saved.' : null),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.description_outlined,
              title: 'Export as Markdown',
              subtitle: 'Readable anywhere. Can’t be imported.',
              onTap: _busy
                  ? null
                  : () => _run(() async =>
              await _backup.exportMarkdown() ? 'Journal saved.' : null),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.file_upload_outlined,
              title: 'Import backup',
              subtitle:
              'Adds missing entries. If a day exists in both, the newer version is kept.',
              onTap: _busy
                  ? null
                  : () => _run(() async {
                final r = await _backup.importJson();
                if (r == null) return null;
                return 'Imported: ${r.added} new, ${r.updated} updated, '
                    '${r.skipped} unchanged.';
              }),
            ),
            const SizedBox(height: 20),
            Text(
              'Exports are plain text files. Keep them somewhere private.',
              style: TextStyle(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}