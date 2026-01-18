import 'package:flutter/material.dart';
import '../utils/sync_helper.dart' as sync_helper;
import '../utils/database_browser_helper.dart';
import '../utils/app_helper.dart' as app_helper;
import '../services/delta_sync_service.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';
import '../screens/setup_google_sheet_screen.dart';
import '../utils/settings_manager.dart';

/// Reusable overflow menu widget for common app-wide menu items
///
/// This widget consolidates all common menu items (sync, debug, etc.) into a single
/// reusable component that can be used across all screens.
///
/// The widget automatically reads login status, sync status, developer mode and sync pause state,
/// and handles all common actions internally. Screens don't need to manage these states or handle
/// common menu actions.
class CommonOverflowMenu extends StatefulWidget {
  /// Optional screen-specific menu items to append
  final List<PopupMenuEntry<String>> additionalMenuItems;

  /// Optional callback for screen-specific menu items only
  final Future<void> Function(String value)? onScreenMenuItemSelected;

  /// Callback to refresh screen state after menu actions
  final VoidCallback? onRefreshState;

  const CommonOverflowMenu({
    super.key,
    this.onScreenMenuItemSelected,
    this.additionalMenuItems = const [],
    this.onRefreshState,
  });

  @override
  State<CommonOverflowMenu> createState() => _CommonOverflowMenuState();
}

class _CommonOverflowMenuState extends State<CommonOverflowMenu> {
  bool _isLoggedIn = false;
  bool _isDeltaSyncing = false;
  bool _isDeveloperMode = false;
  bool _isSyncPaused = false;
  final _deltaSyncService = DeltaSyncService.instance;

  @override
  void initState() {
    super.initState();
    _loadStates();
    // Listen to SettingsManager changes
    SettingsManager.instance.developerMode.addListener(_onSettingsChanged);
    SettingsManager.instance.syncPaused.addListener(_onSettingsChanged);
    SettingsManager.instance.webAppUrl.addListener(_onSettingsChanged);
    SettingsManager.instance.googleSheetId.addListener(_onSettingsChanged);
    SettingsManager.instance.secretCode.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    // Remove listeners
    SettingsManager.instance.developerMode.removeListener(_onSettingsChanged);
    SettingsManager.instance.syncPaused.removeListener(_onSettingsChanged);
    SettingsManager.instance.googleSheetId.removeListener(_onSettingsChanged);
    SettingsManager.instance.webAppUrl.removeListener(_onSettingsChanged);
    SettingsManager.instance.secretCode.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _loadStates();
  }

  Future<void> _loadStates() async {
    final isLoggedIn = SettingsManager.instance.isLoggedIn;
    final isDeltaSyncing = _deltaSyncService.isSyncing;

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isDeltaSyncing = isDeltaSyncing;
        _isDeveloperMode = SettingsManager.instance.isDeveloperMode;
        _isSyncPaused = SettingsManager.instance.isSyncPaused;
      });
    }
  }

  Future<void> _handleMenuSelection(String value) async {
    // Handle common menu actions internally
    final handled = await _handleCommonAction(value);

    // If not a common action, delegate to screen-specific handler
    if (!handled && widget.onScreenMenuItemSelected != null) {
      await widget.onScreenMenuItemSelected!(value);
    }

    // Reload states after menu action (in case developer mode or sync pause was toggled)
    await _loadStates();
    if (mounted) {
      widget.onRefreshState?.call();
    }
  }

  /// Handle common menu actions internally
  /// Returns true if action was handled, false if it should be delegated to screen
  Future<bool> _handleCommonAction(String action) async {
    if (!mounted) return false;

    switch (action) {
      case 'settings':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        return true;

      case 'login':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return true;

      case 'setup_google_sheets':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupGoogleSheetScreen()),
        );
        return true;

      case 'sync':
        await sync_helper.performDeltaSync(context);
        return true;

      case 'stop_sync':
        sync_helper.stopSync(context);
        return true;

      case 'toggle_sync_pause':
        await sync_helper.toggleSyncPauseWithFeedback(context);
        return true;

      case 'view_sync_log':
        await sync_helper.openSyncLog(context);
        return true;

      case 'prepare_condensexd_log':
        await sync_helper.prepareCondensedChangeLog(context);
        return true;

      case 'data_statistics':
        await app_helper.showDataStatistics(context);
        return true;

      case 'db_browser':
        openDatabaseBrowser(context);
        return true;

      default:
        return false; // Not a common action, screen should handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onOpened: () => _loadStates(),
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        // Login (only show when not logged in)
        if (!_isLoggedIn)
          const PopupMenuItem<String>(
            value: 'login',
            child: Row(
              children: [
                Icon(Icons.login, size: 20, color: Colors.green),
                SizedBox(width: 12),
                Text('Login'),
              ],
            ),
          ),

        // Setup Google Sheets (only show when not logged in)
        if (!_isLoggedIn)
          const PopupMenuItem<String>(
            value: 'setup_google_sheets',
            child: Row(
              children: [
                Icon(Icons.cloud_upload, size: 20, color: Colors.blue),
                SizedBox(width: 12),
                Text('Setup Google Sheets'),
              ],
            ),
          ),

        if (!_isLoggedIn) const PopupMenuDivider(),

        // Settings
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20, color: Colors.blue),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Sync with Google Sheets
        PopupMenuItem<String>(
          value: 'sync',
          enabled: _isLoggedIn && !_isDeltaSyncing,
          child: Row(
            children: [
              Icon(Icons.sync,
                  size: 20,
                  color: _isLoggedIn && !_isDeltaSyncing
                      ? Colors.blue
                      : Colors.grey),
              const SizedBox(width: 12),
              Text('Sync with Google Sheets',
                  style: TextStyle(
                      color: _isLoggedIn && !_isDeltaSyncing
                          ? null
                          : Colors.grey)),
            ],
          ),
        ),

        // Stop Sync
        sync_helper.stopSyncMenuItemWidget(isSyncing: _isDeltaSyncing),

        // Pause/Play Sync
        if (_isLoggedIn)
          sync_helper.pausePlaySyncMenuItemWidget(isSyncPaused: _isSyncPaused),

        // View Sync Log
        PopupMenuItem<String>(
          value: 'view_sync_log',
          enabled: _isLoggedIn,
          child: Row(
            children: [
              Icon(Icons.list_alt,
                  size: 20, color: _isLoggedIn ? Colors.blue : Colors.grey),
              const SizedBox(width: 12),
              Text('View Sync Log',
                  style: TextStyle(color: _isLoggedIn ? null : Colors.grey)),
            ],
          ),
        ),

        // Developer mode items
        if (_isDeveloperMode) ...[
          const PopupMenuDivider(),

          // Prepare Condensed Change Log
          const PopupMenuItem<String>(
            value: 'prepare_condensed_log',
            child: Row(
              children: [
                Icon(Icons.compress, size: 20, color: Colors.orange),
                SizedBox(width: 12),
                Text('Prepare Condensed Change Log'),
              ],
            ),
          ),

          const PopupMenuDivider(),

          // Data Statistics
          const PopupMenuItem<String>(
            value: 'data_statistics',
            child: Row(
              children: [
                Icon(Icons.analytics, size: 20, color: Colors.purple),
                SizedBox(width: 12),
                Text('Data Statistics'),
              ],
            ),
          ),

          // Data Browser
          const PopupMenuItem<String>(
            value: 'db_browser',
            child: Row(
              children: [
                Icon(Icons.storage, size: 20, color: Colors.teal),
                SizedBox(width: 12),
                Text('Data Browser'),
              ],
            ),
          ),
        ],

        // Additional screen-specific items
        ...widget.additionalMenuItems,
      ],
    );
  }
}
