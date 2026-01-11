import 'package:flutter/material.dart';
import '../services/delta_sync_service.dart';
import '../services/database_helper.dart';
import '../screens/sync_debug_screen.dart';
import '../utils/settings_manager.dart';

/// Helper functions for sync operations accessible from any screen

/// Perform delta sync with Google Sheets
Future<void> performDeltaSync(BuildContext context,
    {bool showProgressDialog = true}) async {
  final syncService = DeltaSyncService.instance;

  // Check if sync is paused
  final isPaused = SettingsManager.instance.syncPaused.value;
  if (isPaused) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync is paused. Please resume sync to continue.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  // Check if sync is already in progress
  if (syncService.isSyncing) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync is already in progress. Please wait...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  if (!SettingsManager.instance.isLoggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync credentials not configured. Please login first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  // Show progress dialog only if requested
  if (showProgressDialog && context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _SyncProgressDialog(),
    );
  }

  try {
    final result = await syncService.deltaSync(
      onProgress: (message) {
        // Update dialog content via setState in dialog
        if (showProgressDialog && context.mounted) {
          final dialog =
              context.findAncestorStateOfType<_SyncProgressDialogState>();
          dialog?.updateMessage(message);
        }
      },
    );

    if (context.mounted) {
      // Close progress dialog only if it was shown
      if (showProgressDialog) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Delta sync complete: Downloaded ${result.downloaded}, Uploaded ${result.uploaded}'
                : 'Delta sync failed: ${result.error}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      // Close progress dialog if it was shown
      if (showProgressDialog) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delta sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Navigate to sync debug/log screen
Future<void> openSyncLog(BuildContext context) async {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
  );
}

/// Prepare condensed change log
Future<void> prepareCondensedChangeLog(BuildContext context) async {
  final dbHelper = DatabaseHelper.instance;

  try {
    // Show progress
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing condensed change log...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Get last sync timestamp
    final lastSync = SettingsManager.instance.lastSyncTimestamp.value;
    final rawChangeLogs = await dbHelper.getChangeLog(lastSync);
    // Condense change log
    final condensedList = await dbHelper.condenseChangeLog(rawChangeLogs);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Condensed change log prepared: ${condensedList.length} entries',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing condensed change log: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// PopupMenuItem for sync with Google Sheets
/// Note: The login check is done when the menu item is selected, not when it's built
/// This is because PopupMenuButton's itemBuilder cannot be async
PopupMenuItem<String> syncMenuItem() {
  return const PopupMenuItem<String>(
    value: 'sync',
    child: Row(
      children: [
        Icon(Icons.sync, size: 20),
        SizedBox(width: 12),
        Text('Sync with Google Sheets'),
      ],
    ),
  );
}

/// PopupMenuItem for sync log/debug screen
PopupMenuItem<String> syncLogMenuItem() {
  return const PopupMenuItem<String>(
    value: 'sync_log',
    child: Row(
      children: [
        Icon(Icons.bug_report, size: 20, color: Colors.orange),
        SizedBox(width: 12),
        Text('Sync Log'),
      ],
    ),
  );
}

/// PopupMenuItem for preparing condensed change log
PopupMenuItem<String> prepareCondensedChangeLogMenuItem() {
  return const PopupMenuItem<String>(
    value: 'prepare_condensed_log',
    child: Row(
      children: [
        Icon(Icons.compress, size: 20, color: Colors.purple),
        SizedBox(width: 12),
        Text('Prepare Condensed Change Log'),
      ],
    ),
  );
}

/// PopupMenuItem for stopping sync
PopupMenuItem<String> stopSyncMenuItem(bool isSyncing) {
  return PopupMenuItem<String>(
    value: 'stop_sync',
    enabled: isSyncing,
    child: Row(
      children: [
        Icon(
          Icons.stop,
          size: 20,
          color: isSyncing ? Colors.red : Colors.grey,
        ),
        const SizedBox(width: 12),
        Text(
          'Stop Sync with Google Sheets',
          style: TextStyle(
            color: isSyncing ? null : Colors.grey,
          ),
        ),
      ],
    ),
  );
}

/// Stop the current sync operation
void stopSync(BuildContext context) {
  final syncService = DeltaSyncService.instance;
  syncService.stopSync();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync stop requested. Sync will terminate soon...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Progress dialog for sync operations
class _SyncProgressDialog extends StatefulWidget {
  const _SyncProgressDialog();

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  String _message = 'Starting sync...';
  final List<String> _messageHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void updateMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
        _messageHistory.add(message);

        // Auto-scroll to bottom when new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Syncing'),
          const Spacer(),
          Text(
            '${_messageHistory.length} steps',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            // Current message prominently displayed
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message history
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _messageHistory.length,
                itemBuilder: (context, index) {
                  final msg = _messageHistory[index];
                  final isLatest = index == _messageHistory.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: isLatest ? Colors.blue[50] : null,
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLatest ? Colors.blue[900] : Colors.grey[700],
                        fontWeight:
                            isLatest ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: Sync may take several minutes on first run',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
            );
          },
          child: const Text('View Sync Log'),
        ),
        TextButton(
          onPressed: () {
            // Note: This won't actually cancel the sync in progress,
            // but will close the dialog so user can continue using app
            Navigator.of(context).pop();
          },
          child: const Text('Close Dialog'),
        ),
      ],
    );
  }
}

/// Sync menu item with optional busy state
PopupMenuItem<String> syncMenuItemWidget({bool isSyncing = false}) {
  return PopupMenuItem<String>(
    value: 'sync',
    child: Row(
      children: [
        if (isSyncing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          const Icon(Icons.sync, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        const Text('Sync with Google Sheets'),
      ],
    ),
  );
}

/// Stop Sync menu item with conditional enable
PopupMenuItem<String> stopSyncMenuItemWidget({bool isSyncing = false}) {
  return PopupMenuItem<String>(
    value: 'stop_sync',
    enabled: isSyncing,
    child: Row(
      children: [
        Icon(
          Icons.stop,
          size: 20,
          color: isSyncing ? Colors.red : Colors.grey,
        ),
        const SizedBox(width: 12),
        Text(
          'Stop Sync',
          style: TextStyle(
            color: isSyncing ? null : Colors.grey,
          ),
        ),
      ],
    ),
  );
}

/// PopupMenuItem widget for pause/play sync toggle (ListTile version)
PopupMenuItem<String> pausePlaySyncMenuItemWidget(
    {required bool isSyncPaused}) {
  return PopupMenuItem<String>(
    value: 'toggle_sync_pause',
    child: ListTile(
      leading: Icon(
        isSyncPaused ? Icons.play_arrow : Icons.pause,
        size: 20,
      ),
      title: Text(isSyncPaused ? 'Play Sync' : 'Pause Sync'),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

/// Toggle sync pause state and show snackbar
Future<void> toggleSyncPauseWithFeedback(BuildContext context) async {
  await SettingsManager.instance
      .setSyncPaused(!SettingsManager.instance.syncPaused.value);
  final isPaused = SettingsManager.instance.syncPaused.value;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPaused
              ? 'Sync paused. Automatic sync disabled.'
              : 'Sync resumed. Automatic sync enabled.',
        ),
        backgroundColor: isPaused ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// View Sync Log menu item (renamed from Sync Log)
PopupMenuItem<String> viewSyncLogMenuItem() {
  return const PopupMenuItem<String>(
    value: 'sync_log',
    child: Row(
      children: [
        Icon(Icons.list_alt, size: 20, color: Colors.blue),
        SizedBox(width: 12),
        Text('View Sync Log'),
      ],
    ),
  );
}
