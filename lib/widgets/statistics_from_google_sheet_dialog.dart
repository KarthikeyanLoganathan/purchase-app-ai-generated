import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../services/export_import_service.dart';
import '../services/app_info_service.dart';
import '../utils/settings_manager.dart';
import '../utils/sheet_metadata.dart';
import '../utils/app_helper.dart' as apphelper;
import 'google_drive_file_picker.dart';

/// Dialog for viewing data statistics from Google Sheets
class StatisticsFromGoogleSheetDialog extends StatefulWidget {
  const StatisticsFromGoogleSheetDialog({super.key});

  @override
  State<StatisticsFromGoogleSheetDialog> createState() =>
      _StatisticsFromGoogleSheetDialogState();
}

class _StatisticsFromGoogleSheetDialogState
    extends State<StatisticsFromGoogleSheetDialog> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive',
    ],
  );

  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String _statusMessage = '';
  String? _existingSheetId;
  String? _existingSheetName;
  bool _isLoadingSheetInfo = false;
  Map<String, int>? _statistics;

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
        _statistics = null;
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
            _statistics = null; // Clear statistics when changing sheet
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

  Future<void> _loadStatistics() async {
    if (_existingSheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Google Sheet selected"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentGoogleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to Google first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Reading statistics from Google Sheets...';
      });
    }

    try {
      final client = await _getAuthenticatedClient();

      final exportImportService = ExportImportService();
      final statistics =
          await exportImportService.readDataStatisticsFromGoogleSheet(
        sheetId: _existingSheetId!,
        client: client,
      );

      client.close();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
          _statistics = statistics;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to read statistics: $e';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read statistics: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = _currentGoogleUser != null;
    final bool hasSheet = _existingSheetId != null;

    return AlertDialog(
      title: const Text('Data Statistics in Google Sheet'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Google Sign-in
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSignedIn ? Icons.check_circle : Icons.login,
                            color: isSignedIn ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Step 1: Google Sign-In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isSignedIn)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signed in as: ${_currentGoogleUser!.email}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  _isLoading ? null : _handleGoogleSignOut,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Sign In with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: Select Google Sheet
              if (isSignedIn)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasSheet ? Icons.check_circle : Icons.folder,
                              color: hasSheet ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Step 2: Select Google Sheet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingSheetInfo)
                          const Center(child: CircularProgressIndicator())
                        else if (hasSheet && _existingSheetName != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Sheet: $_existingSheetName',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _changeGoogleSheet,
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('Change Sheet'),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No Google Sheet selected',
                                style: TextStyle(color: Colors.orange),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _changeGoogleSheet,
                                icon: const Icon(Icons.file_open, size: 18),
                                label: const Text('Select Sheet'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Step 3: Load Statistics
              if (isSignedIn && hasSheet)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _statistics != null
                                  ? Icons.check_circle
                                  : Icons.bar_chart,
                              color: _statistics != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Step 3: Load Statistics',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadStatistics,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(
                              _isLoading ? 'Loading...' : 'Load Statistics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Display Statistics
              if (_statistics != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assessment, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Statistics',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        apphelper.embedStatisticsInWidget(_statistics!),
                      ],
                    ),
                  ),
                ),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Card(
                  color: _statusMessage.startsWith('Failed') ||
                          _statusMessage.contains('error')
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _statusMessage.startsWith('Failed') ||
                                  _statusMessage.contains('error')
                              ? Icons.error
                              : Icons.info,
                          color: _statusMessage.startsWith('Failed') ||
                                  _statusMessage.contains('error')
                              ? Colors.red
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _statusMessage.startsWith('Failed') ||
                                      _statusMessage.contains('error')
                                  ? Colors.red.shade900
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
