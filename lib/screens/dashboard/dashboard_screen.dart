import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import 'dashboard_overview.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Hộp thoại Sao lưu & Quản lý dữ liệu người dùng
  void _showDataManagementDialog(BuildContext context) {
    final state = context.read<AppStateProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.storage, color: AppTheme.accentCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'Data & Backup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player photos and PR media changes are saved locally on this device.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.copy, color: AppTheme.accentCyan, size: 20),
              ),
              title: const Text(
                'Copy backup JSON',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Copy all player records and updated photos to the clipboard',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                final jsonStr = jsonEncode(
                  state.players.map((p) => p.toJson()).toList(),
                );
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All player data copied to clipboard!'),
                  ),
                );
              },
            ),
            const Divider(color: AppTheme.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(
                  Icons.restore_page,
                  color: AppTheme.lfcYellow,
                  size: 20,
                ),
              ),
              title: const Text(
                'Restore from backup',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Paste a backup to restore photos and player stats',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.of(dialogCtx).pop();
                _showRestoreDialog(context);
              },
            ),
            const Divider(color: AppTheme.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.refresh, color: AppTheme.lfcRed, size: 20),
              ),
              title: const Text(
                'Reset to defaults',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lfcRed,
                ),
              ),
              subtitle: const Text(
                'Remove custom photos and restore the original data',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () async {
                await state.resetToDefaultMockData();
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Liverpool squad restored to default data!',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (restoreCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text(
          'Paste backup data',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Paste your backup JSON...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(restoreCtx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              try {
                final List<dynamic> list = jsonDecode(controller.text.trim());
                for (final item in list) {
                  final p = Player.fromJson(item as Map<String, dynamic>);
                  await context.read<AppStateProvider>().updatePlayer(p);
                }
                if (context.mounted) {
                  Navigator.of(restoreCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data restored successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid backup data: $e')),
                  );
                }
              }
            },
            child: const Text('Restore data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liverpool PMS'),
        actions: [
          IconButton(
            tooltip: 'Data & Backup',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => _showDataManagementDialog(context),
          ),
        ],
      ),
      body: state.isInitialized
          ? DashboardOverview(
              state: state,
              onNavigateTab: widget.onNavigateTab,
              onManageData: () => _showDataManagementDialog(context),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
