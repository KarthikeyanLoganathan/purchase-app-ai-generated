import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:purchase_app/base/model_definition.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../base/data_definition.dart';
import '../services/export_import_service.dart';
import '../services/login_service.dart';
import '../services/app_info_service.dart';
import '../screens/home_screen.dart';
import 'import_sample_data_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/common_overflow_menu.dart';
import '../widgets/upload_to_google_sheet_dialog.dart';
import '../widgets/import_from_google_sheet_dialog.dart';
import '../widgets/statistics_from_google_sheet_dialog.dart';
import '../utils/settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _developerMode = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasGoogleSheetId = false;
  final _loginService = LoginService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoggedIn = SettingsManager.instance.isLoggedIn;
    });
  }

  Future<void> _loadSettings() async {
    final googleSheetId = SettingsManager.instance.googleSheetId.value;
    setState(() {
      _developerMode = SettingsManager.instance.isDeveloperMode;
      _hasGoogleSheetId = googleSheetId != null && googleSheetId.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _toggleDeveloperMode(bool value) async {
    await SettingsManager.instance.setDeveloperMode(value);
    setState(() {
      _developerMode = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Developer mode enabled' : 'Developer mode disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _importSampleData() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportSampleDataScreen()),
    );
  }

  Future<void> _exportData() async {
    try {
      // Show loading dialog with export summary
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Exporting database to CSV files...'),
                    SizedBox(height: 8),
                    Text(
                      'This may take a moment',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      final exportService = ExportImportService();

      // Get export summary first
      final summary = await exportService.getCsvExportSummary();

      // Export all tables to zip
      final zipFilePath = await exportService.exportAllTablesToCsvZip();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog with option to share
      if (mounted) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Database exported successfully!'),
                const SizedBox(height: 16),
                const Text(
                  'Export Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Tables: ${summary['totalTables']}'),
                Text('Total Rows: ${summary['totalRows']}'),
                const SizedBox(height: 8),
                Text(
                  'File: ${zipFilePath.split('/').last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'save'),
                icon: const Icon(Icons.download),
                label: const Text('Save to Downloads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'share'),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (action == 'share') {
          await exportService.shareExportedCsvZip(zipFilePath);
        } else if (action == 'save') {
          try {
            final savedPath =
                await exportService.saveCsvZipToDownloads(zipFilePath);
            if (mounted) {
              // Show dialog with Open and OK options
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('File Saved'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File saved successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Location:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        savedPath,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Open the folder containing the file
                        final directory =
                            savedPath.substring(0, savedPath.lastIndexOf('/'));

                        try {
                          if (Platform.isAndroid) {
                            // Use Android Intent to open Files app directly
                            final intent = AndroidIntent(
                              action: 'android.intent.action.VIEW',
                              data: Uri.parse(
                                      'content://com.android.externalstorage.documents/document/primary:${directory.split('/').last}')
                                  .toString(),
                              type: 'resource/folder',
                              package:
                                  'com.google.android.documentsui', // Google Files app
                            );
                            await intent.launch();
                          } else {
                            // Fallback to OpenFile for other platforms
                            final result = await OpenFile.open(directory);
                            if (result.type != ResultType.done && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // If Files app fails, try generic folder open
                          final result = await OpenFile.open(directory);
                          if (result.type != ResultType.done && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save file: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Pick a zip file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select CSV zip file to import',
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled the picker
        return;
      }

      final zipFilePath = result.files.single.path!;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Importing data from CSV files...'),
                      SizedBox(height: 8),
                      Text(
                        'This may take a moment',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      // Import from zip file
      final importService = ExportImportService();
      final importResult = await importService.importFromZipFile(zipFilePath);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show results dialog
      if (mounted) {
        final success = importResult['success'] ?? false;
        final totalRecords = importResult['totalRecords'] ?? 0;
        final totalErrors = importResult['totalErrors'] ?? 0;
        final results = importResult['results'] as Map<String, int>? ?? {};
        final errors = importResult['errors'] as List<String>? ?? [];

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.warning,
                  color: success ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(success
                    ? 'Import Successful'
                    : 'Import Completed with Errors'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Records Imported: $totalRecords'),
                  if (totalErrors > 0) Text('Errors: $totalErrors'),
                  const SizedBox(height: 16),
                  if (results.isNotEmpty) ...[
                    const Text(
                      'Import Details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...results.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text('${entry.key}: ${entry.value} records'),
                      ),
                    ),
                  ],
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Errors:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...errors.map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          error,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _uploadToGoogleSheets() async {
    await showDialog(
      context: context,
      builder: (_) => const UploadToGoogleSheetDialog(),
    );
  }

  Future<void> _importFromGoogleSheets() async {
    await showDialog(
      context: context,
      builder: (_) => const ImportFromGoogleSheetDialog(),
    );
  }

  Future<void> _clearAllData() async {
    // Build the table list dynamically from the displayNames map
    final tableList = DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
      ModelTypes.log
    ])
        .map((name) => DataDefinition.getModelDefinition(name)!.displayName)
        .map((name) => '• $name')
        .join('\n');

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: Text(
          'This will permanently delete all data from the database including:\n\n'
          '$tableList\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (shouldClear == true && mounted) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Clearing database...'),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        final dbHelper = DatabaseHelper.instance;
        await dbHelper.clearAllData();

        // Clear last sync timestamp
        await SettingsManager.instance.setLastSyncTimestamp(null);

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been cleared successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still open
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _login() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    // If login was successful, refresh login status
    if (result == true && mounted) {
      await _checkLoginStatus();
    }
  }

  Future<void> _logout() async {
    // Check for pending sync changes
    final dbHelper = DatabaseHelper.instance;
    final hasPending = await dbHelper.hasPendingChanges();

    String logoutMessage =
        'Are you sure you want to logout? This will clear your sync credentials';
    if (hasPending) {
      logoutMessage +=
          ' and you have unsynced changes that will remain on this device';
    }
    logoutMessage += '.';

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(logoutMessage),
            if (hasPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have pending changes that are not synced!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: hasPending ? Colors.orange : null),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Use LoginService to logout
      await _loginService.logout();

      if (mounted) {
        // Navigate to home screen and replace the entire stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleLoginLogout() {
    if (_isLoggedIn) {
      _logout();
    } else {
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              // Refresh login status after any menu action
              await _checkLoginStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Developer Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Developer Mode'),
                  subtitle: const Text(
                    'Enable additional menu options for debugging and data management',
                  ),
                  value: _developerMode,
                  onChanged: _toggleDeveloperMode,
                  secondary: const Icon(Icons.developer_mode),
                ),
                if (_developerMode) ...[
                  ListTile(
                    leading: const Icon(Icons.download, color: Colors.green),
                    title: const Text('Export Data'),
                    subtitle: const Text(
                      'Export all database tables to CSV files in a zip archive',
                    ),
                    onTap: _exportData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload, color: Colors.orange),
                    title: const Text('Import Data'),
                    subtitle: const Text(
                      'Import data from a zip file containing CSV tables',
                    ),
                    onTap: _importData,
                  ),
                  ListTile(
                    leading: Icon(Icons.upload_file,
                        color: _isLoggedIn ? Colors.grey : Colors.blue),
                    title: const Text('Import Sample Data'),
                    subtitle: Text(_isLoggedIn
                        ? 'Disabled when sync credentials are configured'
                        : 'Load sample data for testing'),
                    enabled: !_isLoggedIn,
                    onTap: _isLoggedIn ? null : _importSampleData,
                  ),
                  // Upload to Google Sheets
                  if (_hasGoogleSheetId)
                    ListTile(
                      leading:
                          const Icon(Icons.cloud_upload, color: Colors.green),
                      title: const Text('Upload to Google Sheets'),
                      subtitle:
                          const Text('Upload all local data to Google Sheets'),
                      onTap: _uploadToGoogleSheets,
                    ),
                  // Data Statistics in Google Sheets
                  if (_hasGoogleSheetId)
                    ListTile(
                      leading:
                          const Icon(Icons.bar_chart, color: Colors.purple),
                      title: const Text('Data Statistics in Google Sheets'),
                      subtitle:
                          const Text('View record counts in Google Sheets'),
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) =>
                              const StatisticsFromGoogleSheetDialog(),
                        );
                      },
                    ),
                  // Import from Google Sheets
                  if (_hasGoogleSheetId)
                    ListTile(
                      leading:
                          const Icon(Icons.cloud_download, color: Colors.blue),
                      title: const Text('Import from Google Sheets'),
                      subtitle:
                          const Text('Import all data from Google Sheets'),
                      onTap: _importFromGoogleSheets,
                    ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Clear All Data'),
                    subtitle:
                        const Text('Permanently delete all data from database'),
                    onTap: _clearAllData,
                  ),
                ],
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text('Version'),
                  subtitle: Text(AppInfoService.instance.fullVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.blue),
                  title: const Text('Package Name'),
                  subtitle: Text(AppInfoService.instance.packageName),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy package name',
                    onPressed: () {
                      // Copy to clipboard would require clipboard package
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Package: ${AppInfoService.instance.packageName}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    _isLoggedIn ? Icons.logout : Icons.login,
                    color: _isLoggedIn ? Colors.red : Colors.green,
                  ),
                  title: Text(_isLoggedIn ? 'Logout' : 'Login'),
                  subtitle: Text(
                    _isLoggedIn
                        ? 'Clear sync credentials and logout'
                        : 'Login to sync with Google Sheets',
                  ),
                  onTap: _handleLoginLogout,
                ),
              ],
            ),
    );
  }
}

// Widget Preview for VS Code
class SettingsScreenPreview extends StatelessWidget {
  const SettingsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SettingsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
