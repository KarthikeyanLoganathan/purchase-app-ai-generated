import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/export_import_service.dart';
import '../services/app_info_service.dart';
import '../utils/settings_manager.dart';
import '../utils/sheet_metadata.dart';
import 'google_drive_file_picker.dart';

/// Dialog for importing data from Google Sheets
class ImportFromGoogleSheetDialog extends StatefulWidget {
  const ImportFromGoogleSheetDialog({super.key});

  @override
  State<ImportFromGoogleSheetDialog> createState() =>
      _ImportFromGoogleSheetDialogState();
}

class _ImportFromGoogleSheetDialogState
    extends State<ImportFromGoogleSheetDialog> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive',
    ],
  );

  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isImporting = false;
  String? _existingSheetId;
  String? _existingSheetName;
  bool _isLoadingSheetInfo = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSheetInfo();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _currentGoogleUser = account;
        });
      }
      // Load existing Google resources when signed in
      if (account != null) {
        _loadExistingSheetInfo();
      }
    });

    // Try silent sign-in
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      // Silent sign-in failed, user will need to sign in manually
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = 'Signing in to Google...';
        });
      }

      await _googleSignIn.signIn();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Sign-in failed: $e';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await _googleSignIn.signOut();
    if (mounted) {
      setState(() {
        _statusMessage = '';
      });
    }
  }

  Future<void> _loadExistingSheetInfo() async {
    final sheetId = SettingsManager.instance.googleSheetId.value;

    if (sheetId != null && sheetId.isNotEmpty && _currentGoogleUser != null) {
      if (mounted) {
        setState(() {
          _isLoadingSheetInfo = true;
        });
      }

      try {
        final client = await _getAuthenticatedClient();
        final driveApi = drive.DriveApi(client);
        final file = await driveApi.files.get(
          sheetId,
          $fields: "name,trashed",
        ) as drive.File;

        client.close();

        if (file.trashed != true) {
          if (mounted) {
            setState(() {
              _existingSheetId = sheetId;
              _existingSheetName = file.name ?? "Unknown";
              _isLoadingSheetInfo = false;
            });
          }
        } else {
          // Sheet is trashed, clear it
          SettingsManager.instance.setGoogleSheetId(null);
          if (mounted) {
            setState(() {
              _existingSheetId = null;
              _existingSheetName = null;
              _isLoadingSheetInfo = false;
            });
          }
        }
      } catch (e) {
        // Sheet not accessible, clear it
        SettingsManager.instance.setGoogleSheetId(null);
        if (mounted) {
          setState(() {
            _existingSheetId = null;
            _existingSheetName = null;
            _isLoadingSheetInfo = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _existingSheetId = sheetId;
          _existingSheetName = null;
          _isLoadingSheetInfo = false;
        });
      }
    }
  }

  Future<void> _changeGoogleSheet() async {
    if (_currentGoogleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to Google first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final client = await _getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Show the Google Drive file picker
      final selectedFileId = await showDialog<String>(
        context: context,
        builder: (context) => GoogleDriveFilePicker(
          driveApi: driveApi,
          mimeTypeFilter: 'application/vnd.google-apps.spreadsheet',
          title: 'Select Google Sheet',
          appPropertyFilter: {
            SheetMetadata.appPropertyPackageNameKey: AppInfoService.instance
                .appProperties[SheetMetadata.appPropertyPackageNameKey]!,
          },
        ),
      );

      client.close();

      if (selectedFileId == null) {
        // User cancelled
        return;
      }

      // Fetch the new sheet details
      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Loading sheet information...";
        });
      }

      try {
        final newClient = await _getAuthenticatedClient();
        final newDriveApi = drive.DriveApi(newClient);

        // Get sheet name
        final file = await newDriveApi.files.get(
          selectedFileId,
          $fields: "name,trashed",
        ) as drive.File;

        if (file.trashed == true) {
          throw Exception("Selected sheet is in trash");
        }

        final sheetName = file.name ?? "Unknown";
        newClient.close();

        // Save the new sheet ID
        await SettingsManager.instance.setGoogleSheetId(selectedFileId);

        // Update UI
        if (mounted) {
          setState(() {
            _existingSheetId = selectedFileId;
            _existingSheetName = sheetName;
            _isLoading = false;
            _statusMessage = "Sheet changed to: $sheetName";
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sheet changed to: $sheetName"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = "Failed to load sheet: $e";
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load sheet: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<auth.AuthClient> _getAuthenticatedClient() async {
    final authentication = await _currentGoogleUser!.authentication;
    final credentials = auth.AccessCredentials(
      auth.AccessToken(
        "Bearer",
        authentication.accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive",
      ],
    );
    return auth.authenticatedClient(http.Client(), credentials);
  }

  Future<void> _importFromGoogleSheets() async {
    final googleSheetId = SettingsManager.instance.googleSheetId.value;

    if (googleSheetId == null || googleSheetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sheet ID is not configured'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentGoogleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to Google first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isImporting = true;
        _statusMessage = 'Importing data from Google Sheets...';
      });
    }

    try {
      final client = await _getAuthenticatedClient();

      final exportImportService = ExportImportService();
      final result = await exportImportService.importDataFromGoogleSheet(
        sheetId: googleSheetId,
        client: client,
        onProgress: (message) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
            });
          }
        },
      );

      client.close();

      final totalTablesProcessed = result['tablesProcessed'] ?? 0;
      final totalRecordsImported = result['recordsImported'] ?? 0;

      if (mounted) {
        setState(() {
          _isImporting = false;
          _statusMessage = 'Import completed!\n'
              'Tables processed: $totalTablesProcessed\n'
              'Records imported: $totalRecordsImported';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data imported successfully!\n'
              '$totalTablesProcessed tables, $totalRecordsImported records',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Close dialog after successful import
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _statusMessage = 'Import failed: $e';
        });
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import from Google Sheets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing Google Sheet Section
            if (_currentGoogleUser != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_chart, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            "Google Sheet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_existingSheetId == null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "No Google Sheet selected yet. Please select a sheet.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _changeGoogleSheet,
                                icon: const Icon(Icons.folder_open),
                                label: const Text("Select Google Sheet"),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            const Icon(Icons.table_chart,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Current Sheet",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _existingSheetName ?? "Loading...",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    "ID: $_existingSheetId",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoading ? null : _changeGoogleSheet,
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue, size: 20),
                              tooltip: "Change Google Sheet",
                            ),
                            IconButton(
                              onPressed: () async {
                                final url = Uri.parse(
                                    "https://docs.google.com/spreadsheets/d/$_existingSheetId");
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.open_in_new,
                                  color: Colors.blue, size: 20),
                              tooltip: "Open in browser",
                            ),
                          ],
                        ),
                      ],
                      if (_isLoadingSheetInfo)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Google Sign-In Section
            if (_currentGoogleUser == null) ...[
              const Text(
                'Please sign in to Google to import data:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Signing in...' : 'Sign in with Google',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Signed in - show user info and sign out button
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signed in as ${_currentGoogleUser!.email}',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Sign Out from Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Import Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importFromGoogleSheets,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_download, color: Colors.white),
                  label: Text(
                    _isImporting ? 'Importing...' : 'Import Data',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Status Message
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
