import 'package:path/path.dart' as path;
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:googleapis/sheets/v4.dart" as sheets;
import "package:googleapis/script/v1.dart" as script;
import "package:googleapis/drive/v3.dart" as drive;
import "package:googleapis_auth/googleapis_auth.dart" as auth;
import "package:http/http.dart" as http;
import "package:purchase_app/utils/settings_manager.dart";
import "package:purchase_app/utils/app_helper.dart" as apphelper;
import "dart:convert";
import "package:url_launcher/url_launcher.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:file_picker/file_picker.dart";
import "../models/local_setting.dart";
import "../services/app_info_service.dart";
import "../services/export_import_service.dart";
import "../widgets/common_overflow_menu.dart";
import "../widgets/google_drive_file_picker.dart";
import "../widgets/import_from_google_sheet_dialog.dart";
import "../utils/sheet_metadata.dart";

// Mobile App Development Steps for Google Sheets/Drive Integration:
// 1. Go to Google Cloud Console
// 2. Create or select a project
// 3. Enable Google Sheets API and Apps Script API
// 4. Create OAuth 2.0 credentials:
//    • Application type: Android
//    • Package name: com.purchase.purchase_app
// 5. Get your SHA-1 certificate fingerprint:
//    Run: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
// 6. Add the SHA-1 to your OAuth client
// 7. Download google-services.json
// 8. Place it in android/app/

/// Screen for automating Google Sheets setup with Apps Script deployment
class SetupGoogleSheetScreen extends StatefulWidget {
  const SetupGoogleSheetScreen({super.key});

  @override
  State<SetupGoogleSheetScreen> createState() => _SetupGoogleSheetScreenState();
}

class _SetupGoogleSheetScreenState extends State<SetupGoogleSheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sheetNameController = TextEditingController();
  final _appCodeController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/script.projects",
      "https://www.googleapis.com/auth/script.deployments",
      "https://www.googleapis.com/auth/drive", // Full drive access to list and manage all files
    ],
    // serverClientId:
    //     "527621704503-6jlc2jtvuo9s047g998ftt1abt5ggjkm.apps.googleusercontent.com",
  );

  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String _statusMessage = "";
  String? _deployedWebAppUrl;
  bool _isSignedIn = false;
  bool _isDeploymentComplete = false;
  String? _currentSpreadsheetId;
  String? _existingSheetId;
  String? _existingSheetName;
  String? _existingScriptId;
  String? _existingScriptName;
  bool _isLoadingExistingInfo = false;
  bool _isSheetsSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSheetInfo();

    // Add listeners to text controllers to update button state
    _sheetNameController.addListener(() {
      setState(() {});
    });
    _appCodeController.addListener(() {
      setState(() {});
    });

    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _currentGoogleUser = account;
          _isSignedIn = account != null;
        });
      }
      // Load existing Google resources when signed in
      if (account != null) {
        _loadExistingGoogleResources();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _loadExistingSheetInfo() async {
    // Try loading from local_settings table first (authoritative source)
    String? savedSheetId = SettingsManager.instance.googleSheetId.value;

    // Fallback to SharedPreferences if not in database
    if (savedSheetId == null) {
      final prefs = await SharedPreferences.getInstance();
      savedSheetId = prefs.getString(LocalSettingsKeys.googleSheetId);
    }

    if (savedSheetId != null && savedSheetId.isNotEmpty) {
      // Fetch the sheet name and verify it's not trashed
      try {
        if (_currentGoogleUser != null) {
          final client = await _getAuthenticatedClient();
          final driveApi = drive.DriveApi(client);

          // Check if the file exists and is not trashed
          final file = await driveApi.files.get(
            savedSheetId,
            $fields: "trashed,name",
          ) as drive.File;

          client.close();

          if (file.trashed == true) {
            debugPrint("[Setup] Saved sheet is in trash: ${file.name}");
            if (mounted) {
              setState(() {
                _statusMessage =
                    "Previous sheet is in trash - will create new one";
              });
            }
            _sheetNameController.text = "My Purchase Data";
          } else {
            final sheetName = file.name ?? "Unknown";
            _sheetNameController.text = sheetName;

            if (mounted) {
              setState(() {
                _statusMessage = "Found existing sheet: $sheetName";
              });
            }
            debugPrint("[Setup] Loaded existing sheet info:");
            debugPrint("[Setup]   Name: $sheetName");
            debugPrint("[Setup]   ID: $savedSheetId");
          }
        } else {
          // Not signed in yet, can"t verify - don"t show misleading message
          debugPrint("[Setup] Found sheet ID (not verified): $savedSheetId");
          _sheetNameController.text = "My Purchase Data";
        }
      } catch (e) {
        debugPrint("[Setup] Could not fetch/verify sheet: $e");
        if (mounted) {
          setState(() {
            _statusMessage =
                "Previous sheet not accessible - will create new one";
          });
        }
        _sheetNameController.text = "My Purchase Data";
      }
    } else {
      _sheetNameController.text = "My Purchase Data";
    }
  }

  @override
  void dispose() {
    _sheetNameController.dispose();
    _appCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Signing in to Google...";
        });
      }

      await _googleSignIn.signIn();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Successfully signed in!";
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Sign in failed: $error";
        });
      }

      if (mounted) {
        // Show detailed error information and configuration instructions
        _showSignInErrorDialog(error.toString());
      }
    }
  }

  void _showSignInErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Google Sign-In Configuration Required"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Error: $error",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                "Google Sign-In requires Android configuration. Please follow these steps:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "1. Go to Google Cloud Console\n"
                "2. Create or select a project\n"
                "3. Enable Google Sheets API and Apps Script API\n"
                "4. Create OAuth 2.0 credentials:\n"
                "   • Application type: Android\n"
                "   • Package name: com.purchase.purchase_app\n"
                "5. Get your SHA-1 certificate fingerprint:\n"
                "   Run: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android\n"
                "6. Add the SHA-1 to your OAuth client\n"
                "7. Download google-services.json\n"
                "8. Place it in android/app/\n\n"
                "Alternative: Use the manual setup option below.",
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualSetupInstructions();
            },
            child: const Text("Manual Setup Guide"),
          ),
        ],
      ),
    );
  }

  void _showManualSetupInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Google Sheets Setup"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Follow these steps to set up Google Sheets manually:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "1. Create a new Google Sheet\n"
                "2. Extensions → Apps Script\n"
                "3. Create a sheet named \"config\" with:\n"
                "   • Headers: name, value, description\n"
                "   • Row 2: APP_CODE, [your-secret-code], the secret\n"
                "4. Copy all files from backend/google-app-script-code/ to the Apps Script project\n"
                "5. Deploy as Web App:\n"
                "   • Execute as: Me\n"
                "   • Who has access: Anyone\n"
                "6. Copy the Web App URL\n"
                "7. In this app, go to Settings/Login and enter:\n"
                "   • Web App URL\n"
                "   • Your secret code (APP_CODE)\n"
                "8. Call the setup endpoint manually or use the setupSheets operation",
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    if (mounted) {
      setState(() {
        _statusMessage = "";
        _deployedWebAppUrl = null;
      });
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
        "https://www.googleapis.com/auth/script.projects",
        "https://www.googleapis.com/auth/script.deployments",
        "https://www.googleapis.com/auth/drive",
      ],
    );
    return auth.authenticatedClient(http.Client(), credentials);
  }

  Future<void> _deployBackend() async {
    if (!_formKey.currentState!.validate()) {
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
        _statusMessage = "Starting deployment process...";
      });
    }

    try {
      final sheetName = _sheetNameController.text.trim();
      final appCode = _appCodeController.text.trim();

      // Check for existing spreadsheet ID from both sources
      String? spreadsheetId = SettingsManager.instance.googleSheetId.value;

      // Fallback to SharedPreferences
      if (spreadsheetId == null || spreadsheetId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        spreadsheetId = prefs.getString(LocalSettingsKeys.googleSheetId);
      }

      if (spreadsheetId != null && spreadsheetId.isNotEmpty) {
        debugPrint("[Setup] Found existing sheet ID: $spreadsheetId");
      } else {
        debugPrint("[Setup] No existing sheet ID found");
      }

      // Step 1: Create Google Sheet (or use existing)
      if (spreadsheetId != null && spreadsheetId.isNotEmpty) {
        if (mounted) {
          setState(() => _statusMessage = "Verifying existing Google Sheet...");
        }
        debugPrint(
            "[Setup] Verifying existing sheet accessibility and trash status...");
        // Verify the sheet still exists and is not trashed using Drive API
        bool needsNewSheet = false;
        try {
          final client = await _getAuthenticatedClient();
          final driveApi = drive.DriveApi(client);

          // Check if the file is trashed using Drive API
          final file = await driveApi.files.get(
            spreadsheetId,
            $fields: "trashed,name",
          ) as drive.File;

          if (file.trashed == true) {
            debugPrint("[Setup] Sheet is in trash: ${file.name}");
            needsNewSheet = true;
          } else {
            debugPrint(
                "[Setup] Existing sheet verified successfully: ${file.name}");
            debugPrint("[Setup] Sheet ID: $spreadsheetId");
            debugPrint(
                "[Setup] Sheet URL: https://docs.google.com/spreadsheets/d/$spreadsheetId");
          }
          client.close();
        } catch (e) {
          // Sheet doesn't exist anymore or is inaccessible
          debugPrint("[Setup] Previous sheet not accessible: $e");
          needsNewSheet = true;
        }

        if (needsNewSheet) {
          debugPrint("[Setup] Clearing old sheet ID and creating new sheet");
          if (mounted) {
            setState(() => _statusMessage =
                "Previous sheet in trash, creating new one...");
          }

          // Clear saved sheet ID
          // Note: Sheet name is fetched from API, not stored
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(LocalSettingsKeys.googleSheetId);
          await SettingsManager.instance.setGoogleSheetId(null);
          debugPrint("[Setup] Cleared google_sheet_id");

          spreadsheetId = await _createGoogleSheet(sheetName);

          // Save to both SharedPreferences and local_settings
          await prefs.setString(LocalSettingsKeys.googleSheetId, spreadsheetId);
          await SettingsManager.instance.setGoogleSheetId(spreadsheetId);
          debugPrint("[Setup] Created new sheet: $spreadsheetId");
          debugPrint(
              "[Setup] Sheet URL: https://docs.google.com/spreadsheets/d/$spreadsheetId");

          // Update UI to show newly created sheet in "Existing Google Resources"
          if (mounted) {
            setState(() {
              _existingSheetId = spreadsheetId;
              _existingSheetName = sheetName;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() => _statusMessage = "Creating Google Sheet...");
        }
        debugPrint("[Setup] Creating new Google Sheet...");
        spreadsheetId = await _createGoogleSheet(sheetName);

        // Save to both SharedPreferences and local_settings
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(LocalSettingsKeys.googleSheetId, spreadsheetId);
        await SettingsManager.instance.setGoogleSheetId(spreadsheetId);

        debugPrint("[Setup] Created new sheet: $spreadsheetId");
        debugPrint(
            "[Setup] Sheet URL: https://docs.google.com/spreadsheets/d/$spreadsheetId");

        // Update UI to show newly created sheet in "Existing Google Resources"
        if (mounted) {
          setState(() {
            _existingSheetId = spreadsheetId;
            _existingSheetName = sheetName;
          });
        }
      }

      // Step 2: Create/update config sheet
      if (mounted) {
        setState(() => _statusMessage = "Setting up configuration sheet...");
      }
      debugPrint("[Setup] Setting up config sheet...");
      await _createConfigSheet(spreadsheetId, appCode);
      debugPrint("[Setup] Config sheet ready");

      // Step 3: Get Apps Script project ID
      if (mounted) {
        setState(() => _statusMessage = "Accessing Apps Script project...");
      }
      debugPrint("[Setup] Creating Apps Script project...");
      final scriptId = await _getScriptProjectId(spreadsheetId, sheetName);
      debugPrint("[Setup] Script project ID: $scriptId");

      // Update UI to show Apps Script project in "Existing Google Resources"
      if (mounted) {
        setState(() {
          _existingScriptId = scriptId;
          _existingScriptName = sheetName;
        });
      }

      // Step 4: Copy backend JavaScript files
      if (mounted) {
        setState(() => _statusMessage = "Deploying backend code...");
      }
      debugPrint("[Setup] Copying backend files to Apps Script project...");
      await _copyBackendFiles(scriptId);
      debugPrint("[Setup] Backend files copied successfully");

      // Step 5: Deploy as Web App
      if (mounted) {
        setState(() => _statusMessage = "Deploying Web App...");
      }
      debugPrint("[Setup] Creating Web App deployment...");
      final webAppUrl = await _deployWebApp(scriptId);
      debugPrint("[Setup] Web App URL: $webAppUrl");

      // Save deployment info but don't call setupSheets yet
      // User needs to authorize the app first
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Deployment complete! Now authorize the app...";
          _deployedWebAppUrl = webAppUrl;
          _isDeploymentComplete = true;
          _currentSpreadsheetId = spreadsheetId;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Backend deployed! Please authorize the app in Step 4"),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Deployment failed: $error";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Deployment failed: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _setupSheets() async {
    if (_currentSpreadsheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please deploy backend first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = "Initializing Google Sheets...";
      });
    }

    try {
      final appCode = _appCodeController.text.trim();
      debugPrint("[Setup] Calling CheckSheetSetup operation...");
      final checkSheetSetupResult =
          await _callCheckSheetSetupEndpoint(_deployedWebAppUrl!, appCode);
      debugPrint("[Setup] Called CheckSheetSetup operation.");

      if (!checkSheetSetupResult) {
        // Step 6: Setup sheets via Web App
        debugPrint("[Setup] Calling setupSheets operation...");
        await _callSetupSheetsEndpoint(_deployedWebAppUrl!, appCode);
        debugPrint("[Setup] Sheets initialized successfully");
      }

      // Step 7: Save credentials and sheet info
      debugPrint("[Setup] Saving credentials...");
      await SettingsManager.instance
          .setWebAppUrlAndSecretCode(_deployedWebAppUrl!, appCode);

      // Save sheet ID in both SharedPreferences and local_settings table
      // Note: Sheet name is fetched from API when needed, not stored
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          LocalSettingsKeys.googleSheetId, _currentSpreadsheetId!);
      await SettingsManager.instance.setGoogleSheetId(_currentSpreadsheetId!);

      debugPrint("[Setup] Saved sheet ID: $_currentSpreadsheetId");
      debugPrint("[Setup] Saved web_app_url and secret_code to local_settings");

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Setup completed successfully!";
          _isSheetsSetupComplete = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Google Sheets setup completed! Proceed to Step 6 to import data."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Setup failed: $error";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Setup failed: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Show Data Statistics from Google Sheets
  Future<void> _showDataStatistics() async {
    if (_currentSpreadsheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Google Sheet configured"),
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
        sheetId: _currentSpreadsheetId!,
        client: client,
      );

      client.close();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }

      if (mounted) {
        await apphelper.showDataStatisticsByTableCount(
          context,
          statistics,
          'Data Statistics in Google Sheet',
        );
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

  // Step 6 Functions: Import Data
  Future<void> _importFromGoogleSheet() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => const ImportFromGoogleSheetDialog(),
    );
  }

  Future<void> _importSampleData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Sample Data'),
        content: const Text(
          'This will clear all existing data and import sample data from assets.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Importing sample data...';
      });
    }

    try {
      final importService = ExportImportService();
      final result = await importService.importFromSampleDataAssets();

      if (result['success'] == true) {
        // Initialize change log from imported data
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage =
                'Sample data imported successfully! ${result['totalImported']} records imported.';
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Sample data imported: ${result['totalImported']} records'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Import failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Future<void> _importFromZipFile() async {
    try {
      // Pick zip file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final zipFilePath = result.files.first.path;
      if (zipFilePath == null) {
        throw Exception('Could not access file path');
      }

      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = 'Importing data from zip file...';
        });
      }

      final importService = ExportImportService();
      final importResult = await importService.importFromZipFile(zipFilePath);

      final success = importResult['success'] ?? false;
      final totalRecords = importResult['totalRecords'] ?? 0;
      final totalErrors = importResult['totalErrors'] ?? 0;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = success
              ? 'Import successful! $totalRecords records imported.'
              : 'Import completed with $totalErrors errors.';
        });
      }

      // Show detailed results dialog
      if (mounted) {
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
                          fontWeight: FontWeight.bold, color: Colors.red),
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
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  /// Step 7: Upload Data to Google Sheets
  Future<void> _uploadDataToGoogleSheets() async {
    if (_currentSpreadsheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("No Google Sheet available. Please complete setup first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Data to Google Sheets'),
        content: const Text(
          'This will upload all local data to Google Sheets and clear change logs.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Uploading data to Google Sheets...';
      });
    }

    try {
      final client = await _getAuthenticatedClient();

      final exportImportService = ExportImportService();
      final result = await exportImportService.uploadDataToGoogleSheets(
        sheetId: _currentSpreadsheetId!,
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
      final totalRecordsUploaded = result['recordsUploaded'] ?? 0;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Upload completed!\n'
              'Tables processed: $totalTablesProcessed\n'
              'Records uploaded: $totalRecordsUploaded';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data uploaded successfully!\n'
              '$totalTablesProcessed tables, $totalRecordsUploaded records',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Upload failed: $e';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<String> _createGoogleSheet(String sheetName) async {
    final client = await _getAuthenticatedClient();
    final sheetsApi = sheets.SheetsApi(client);
    final driveApi = drive.DriveApi(client);

    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(title: sheetName),
    );

    final response = await sheetsApi.spreadsheets.create(spreadsheet);
    final spreadsheetId = response.spreadsheetId!;

    // Update the created spreadsheet with app properties using Drive API
    try {
      final file = drive.File()
        ..appProperties = {
          ...AppInfoService.instance.appProperties,
          'created-at': DateTime.now().toIso8601String(),
          'purpose': 'purchase-tracking',
        };

      await driveApi.files.update(
        file,
        spreadsheetId,
        $fields: 'appProperties',
      );
      debugPrint('[Setup] Added app properties to spreadsheet');
    } catch (e) {
      debugPrint('[Setup] Warning: Could not add app properties: $e');
    }

    client.close();

    return spreadsheetId;
  }

  Future<void> _createConfigSheet(String spreadsheetId, String appCode) async {
    final client = await _getAuthenticatedClient();
    final sheetsApi = sheets.SheetsApi(client);

    try {
      // Get existing spreadsheet to check for config sheet
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final configSheet = spreadsheet.sheets?.firstWhere(
        (sheet) => sheet.properties?.title == "config",
        orElse: () => sheets.Sheet(),
      );

      // If config sheet doesn't exist, create it
      if (configSheet?.properties?.sheetId == null) {
        final addSheetRequest = sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: "config"),
          ),
        );

        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: [addSheetRequest]),
          spreadsheetId,
        );
      }

      // Update config sheet values (works for both new and existing sheets)
      final valueRange = sheets.ValueRange.fromJson({
        "values": [
          ["name", "value", "description"],
          ["APP_CODE", appCode, "the secret"],
        ],
      });

      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        "config!A1:C2",
        valueInputOption: "RAW",
      );
    } finally {
      client.close();
    }
  }

  Future<String> _getScriptProjectId(
      String spreadsheetId, String projectName) async {
    final client = await _getAuthenticatedClient();
    final sheetsApi = sheets.SheetsApi(client);
    final scriptApi = script.ScriptApi(client);

    try {
      // Step 1: Try to get script ID from developer metadata
      debugPrint("[Setup] Checking developer metadata for script ID...");
      int? oldMetadataId;
      try {
        final spreadsheet = await sheetsApi.spreadsheets.get(
          spreadsheetId,
          $fields: "developerMetadata",
        );

        if (spreadsheet.developerMetadata != null) {
          for (var metadata in spreadsheet.developerMetadata!) {
            if (metadata.metadataKey == SheetMetadata.theGoogleAppScriptId) {
              final scriptId = metadata.metadataValue!;
              debugPrint("[Setup] Found script ID in metadata: $scriptId");

              // Verify the script still exists
              try {
                await scriptApi.projects.get(scriptId);
                debugPrint("[Setup] Script ID verified");
                return scriptId;
              } catch (e) {
                debugPrint("[Setup] Script ID in metadata is invalid: $e");
                // Store metadata ID for deletion
                oldMetadataId = metadata.metadataId;
                debugPrint(
                    "[Setup] Will delete old metadata ID: $oldMetadataId");
                // Continue to create new script
              }
            }
          }
        }
      } catch (e) {
        debugPrint("[Setup] Error reading developer metadata: $e");
      }

      // Step 1.5: Delete old invalid metadata if found
      if (oldMetadataId != null) {
        try {
          debugPrint("[Setup] Deleting old invalid metadata...");
          final deleteMetadataRequest = sheets.Request(
            deleteDeveloperMetadata: sheets.DeleteDeveloperMetadataRequest(
              dataFilter: sheets.DataFilter(
                developerMetadataLookup: sheets.DeveloperMetadataLookup(
                  metadataId: oldMetadataId,
                ),
              ),
            ),
          );

          await sheetsApi.spreadsheets.batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(
              requests: [deleteMetadataRequest],
            ),
            spreadsheetId,
          );
          debugPrint("[Setup] Old metadata deleted successfully");
        } catch (e) {
          debugPrint("[Setup] Warning: Could not delete old metadata: $e");
        }
      }

      // Step 2: Create a new Apps Script project bound to the spreadsheet
      debugPrint("[Setup] Creating new Apps Script project...");
      final project = script.CreateProjectRequest(
        title: projectName,
        parentId: spreadsheetId,
      );

      final createdProject = await scriptApi.projects.create(project);
      final scriptId = createdProject.scriptId!;

      debugPrint("[Setup] Created new script ID: $scriptId");

      // Step 3: Store the script ID in developer metadata
      debugPrint("[Setup] Adding script ID to developer metadata...");
      try {
        final createMetadataRequest = sheets.Request(
          createDeveloperMetadata: sheets.CreateDeveloperMetadataRequest(
            developerMetadata: sheets.DeveloperMetadata(
              metadataKey: SheetMetadata.theGoogleAppScriptId,
              metadataValue: scriptId,
              location: sheets.DeveloperMetadataLocation(
                spreadsheet: true,
              ),
              visibility: "DOCUMENT",
            ),
          ),
        );

        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [createMetadataRequest],
          ),
          spreadsheetId,
        );
        debugPrint("[Setup] Script ID stored in developer metadata");
      } catch (e) {
        debugPrint("[Setup] Warning: Could not add developer metadata: $e");
      }

      return scriptId;
    } finally {
      client.close();
    }
  }

  Future<void> _copyBackendFiles(String scriptId) async {
    final client = await _getAuthenticatedClient();
    final scriptApi = script.ScriptApi(client);

    try {
      // Get list of all assets using Flutter's official API
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets().toList();

      // Filter for backend files (JS, HTML, and JSON manifest)
      final jsFiles = allAssets
          .where((key) =>
              key.startsWith("backend/google-app-script-code/") &&
              (key.endsWith(".js") ||
                  key.endsWith(".html") ||
                  key.endsWith("appsscript.json")))
          .toList();

      if (jsFiles.isEmpty) {
        throw Exception("No backend files found in assets");
      }

      // Load all JS files
      final List<script.File> files = [];

      for (final filePath in jsFiles) {
        //final filenameWithExt = path.basename(filePath);
        final ext = path.extension(filePath).toLowerCase();
        final filenameWithoutExt = path.basenameWithoutExtension(filePath);
        final type = switch (ext) {
          '.json' => 'JSON',
          '.html' => 'HTML',
          '.js' => 'SERVER_JS',
          _ => throw Exception('Unsupported file type'),
        };
        final content = await rootBundle.loadString(filePath);
        files.add(script.File(
          name: filenameWithoutExt,
          type: type,
          source: content,
        ));
      }

      // Get current project content to preserve scriptId
      final currentContent = await scriptApi.projects.getContent(scriptId);

      // Update the project content with our files while preserving scriptId
      final newContent = script.Content(
        scriptId: currentContent.scriptId,
        files: files,
      );

      await scriptApi.projects.updateContent(newContent, scriptId);
    } finally {
      client.close();
    }
  }

  Future<String> _deployWebApp(String scriptId) async {
    final client = await _getAuthenticatedClient();
    final scriptApi = script.ScriptApi(client);

    try {
      // Step 1: Create a new version
      debugPrint("[Setup] Creating new version for deployment...");
      final versionRequest = script.Version(description: "Deployment update");
      final version =
          await scriptApi.projects.versions.create(versionRequest, scriptId);
      debugPrint("[Setup] Created version: ${version.versionNumber}");

      // Step 2: Archive existing active deployments
      debugPrint("[Setup] Checking for existing active deployments...");
      final deploymentsList =
          await scriptApi.projects.deployments.list(scriptId);

      final deployments = deploymentsList.deployments;

      if (deployments != null && deployments.isNotEmpty) {
        for (var deployment in deployments) {
          final String? dId = deployment.deploymentId;

          // 1. Skip if it's the HEAD deployment (cannot be archived)
          if (dId == null || dId == "HEAD") continue;

          // 2. Identify if it contains a Web App entry point
          final bool isWebApp = deployment.entryPoints?.any(
                (e) => e.entryPointType == "WEB_APP",
              ) ??
              false;

          if (isWebApp) {
            debugPrint("[Setup] Found active Web App deployment: $dId");
            debugPrint(
                "[Setup]   Updated: ${deployment.updateTime ?? 'unknown'}");

            try {
              debugPrint("[Setup] Archiving deployment $dId...");
              // This moves it to the 'Archived' state in the GAS UI
              await scriptApi.projects.deployments.delete(scriptId, dId);
              debugPrint("[Setup] Successfully archived $dId");
            } catch (e) {
              debugPrint("[Setup] Warning: Failed to archive $dId: $e");
              // Continue with deployment creation even if archiving fails
            }
          }
        }
      } else {
        debugPrint("[Setup] No existing deployments found");
      }

      // Step 3: Create a new deployment with the latest version
      debugPrint(
          "[Setup] Creating new deployment with version ${version.versionNumber}...");

      final deploymentConfig = script.DeploymentConfig(
        scriptId: scriptId,
        versionNumber: version.versionNumber,
        manifestFileName: "appsscript",
        description: "Web App Deployment v${version.versionNumber}",
      );

      final deploy = await scriptApi.projects.deployments
          .create(deploymentConfig, scriptId);

      // Extract URL from new deployment
      final entryPoints = deploy.entryPoints;
      if (entryPoints != null && entryPoints.isNotEmpty) {
        final webAppEntry = entryPoints.firstWhere(
          (entry) => entry.entryPointType == "WEB_APP",
          orElse: () => throw Exception("No Web App entry point found"),
        );
        final webAppUrl = webAppEntry.webApp!.url!;
        debugPrint("[Setup] Created new deployment URL: $webAppUrl");
        return webAppUrl;
      } else {
        throw Exception("Failed to get Web App URL from new deployment");
      }
    } finally {
      client.close();
    }
  }

  Future<void> _loadExistingGoogleResources() async {
    if (_currentGoogleUser == null) return;

    if (mounted) {
      setState(() {
        _isLoadingExistingInfo = true;
      });
    }

    try {
      final sheetId = SettingsManager.instance.googleSheetId.value;

      if (sheetId != null && sheetId.isNotEmpty) {
        // Fetch sheet name from Google API
        try {
          final client = await _getAuthenticatedClient();
          final driveApi = drive.DriveApi(client);
          final file = await driveApi.files.get(
            sheetId,
            $fields: "name,trashed",
          ) as drive.File;

          if (file.trashed != true) {
            if (mounted) {
              setState(() {
                _existingSheetId = sheetId;
                _existingSheetName = file.name ?? "Unknown";
              });
            }

            // Get script ID from developer metadata
            final sheetsApi = sheets.SheetsApi(client);
            try {
              final spreadsheet = await sheetsApi.spreadsheets.get(
                sheetId,
                $fields: "developerMetadata",
              );

              if (spreadsheet.developerMetadata != null) {
                for (var metadata in spreadsheet.developerMetadata!) {
                  if (metadata.metadataKey ==
                      SheetMetadata.theGoogleAppScriptId) {
                    final scriptId = metadata.metadataValue!;

                    // Get script project name
                    final scriptApi = script.ScriptApi(client);
                    try {
                      final project = await scriptApi.projects.get(scriptId);
                      if (mounted) {
                        setState(() {
                          _existingScriptId = scriptId;
                          _existingScriptName = project.title ?? "Unknown";
                        });
                      }
                    } catch (e) {
                      debugPrint(
                          "[Setup] Script project not accessible or doesn't exist: $e");
                      // Script project doesn't exist or is not accessible
                      if (mounted) {
                        setState(() {
                          _existingScriptId = null;
                          _existingScriptName = null;
                        });
                      }
                    }
                    break;
                  }
                }
              } else {
                // No developer metadata found, clear script info
                if (mounted) {
                  setState(() {
                    _existingScriptId = null;
                    _existingScriptName = null;
                  });
                }
              }
            } catch (e) {
              debugPrint("[Setup] Error reading developer metadata: $e");
            }
          } else {
            // Sheet is trashed, clear it
            await SettingsManager.instance.setGoogleSheetId(null);
          }
          client.close();
        } catch (e) {
          debugPrint("[Setup] Error fetching sheet info: $e");
          // Sheet not accessible, clear it
          await SettingsManager.instance.setGoogleSheetId(null);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingInfo = false;
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

        // Get script ID from developer metadata
        String? newScriptId;
        String? newScriptName;

        debugPrint(
            "[Setup] Checking for Apps Script project in developer metadata...");
        try {
          final sheetsApi = sheets.SheetsApi(newClient);
          final spreadsheet = await sheetsApi.spreadsheets.get(
            selectedFileId,
            $fields: "developerMetadata",
          );

          if (spreadsheet.developerMetadata != null) {
            for (var metadata in spreadsheet.developerMetadata!) {
              if (metadata.metadataKey == SheetMetadata.theGoogleAppScriptId) {
                final scriptIdCandidate = metadata.metadataValue!;
                debugPrint("[Setup] Found script ID: $scriptIdCandidate");

                // Get script project name
                final scriptApi = script.ScriptApi(newClient);
                try {
                  final project =
                      await scriptApi.projects.get(scriptIdCandidate);
                  newScriptName = project.title ?? "Unknown";
                  newScriptId = scriptIdCandidate; // Only set if accessible
                  debugPrint("[Setup] Script name: $newScriptName");
                } catch (e) {
                  debugPrint(
                      "[Setup] Script project not accessible or doesn't exist: $e");
                  // Don't set newScriptId if project is not accessible
                  newScriptId = null;
                  newScriptName = null;
                }
                break;
              }
            }
          }

          if (newScriptId == null) {
            debugPrint(
                "[Setup] No accessible script ID found in developer metadata");
          }
        } catch (e) {
          debugPrint("[Setup] Error reading developer metadata: $e");
        }

        newClient.close();

        // Save the new sheet ID
        await SettingsManager.instance.setGoogleSheetId(selectedFileId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(LocalSettingsKeys.googleSheetId, selectedFileId);

        // Update UI
        if (mounted) {
          setState(() {
            _existingSheetId = selectedFileId;
            _existingSheetName = sheetName;
            _existingScriptId = newScriptId;
            _existingScriptName = newScriptName;
            _isLoading = false;
            _statusMessage = newScriptId != null
                ? "Sheet changed to: $sheetName (with bound script: $newScriptName)"
                : "Sheet changed to: $sheetName (no bound script found)";
            _sheetNameController.text = sheetName;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newScriptId != null
                  ? "Sheet changed to: $sheetName\nBound script found: $newScriptName"
                  : "Sheet changed to: $sheetName\nNo bound script found"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
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
        setState(() {
          _isLoading = false;
          _statusMessage = "Failed to open file picker: $e";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open file picker: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGoogleSheet() async {
    if (_existingSheetId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Google Sheet?"),
        content: Text(
          "Are you sure you want to delete the Google Sheet \"$_existingSheetName\"?\n\n"
          "This will permanently delete the sheet and all its data from Google Drive.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = "Deleting Google Sheet...";
      });
    }

    try {
      final client = await _getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Delete the file (moves to trash)
      await driveApi.files.delete(_existingSheetId!);
      client.close();

      // Clear from local_settings
      await SettingsManager.instance.setGoogleSheetId(null);

      if (mounted) {
        setState(() {
          _existingSheetId = null;
          _existingSheetName = null;
          _existingScriptId = null;
          _existingScriptName = null;
          _statusMessage = "Google Sheet deleted successfully";
          _isDeploymentComplete = false; // Re-enable Deploy Backend button
          _deployedWebAppUrl = null;
          _currentSpreadsheetId = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Sheet deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Failed to delete sheet: $e";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete sheet: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _callCheckSheetSetupEndpoint(
      String webAppUrl, String appCode) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {
              "Content-Type": "application/json",
              ...AppInfoService.instance.httpHeaders,
            },
            body: jsonEncode({
              "secret": appCode,
              "operation": "checkSheetSetup",
            }),
          )
          .timeout(const Duration(seconds: 30));

      // Handle 302/301 redirects from Google Apps Script
      dynamic data;
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectMatch =
            RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
        if (redirectMatch != null) {
          final redirectUrl = redirectMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint("[Setup] Following redirect: $redirectUrl");
          final redirectResponse = await http.get(Uri.parse(redirectUrl));

          if (redirectResponse.statusCode != 200) {
            throw Exception(
                "HTTP ${redirectResponse.statusCode}: ${redirectResponse.body}");
          }

          data = jsonDecode(redirectResponse.body);
        } else {
          throw Exception("HTTP 302 redirect but no URL found in response");
        }
      } else if (response.statusCode == 200) {
        data = jsonDecode(response.body);
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }

      // Return the result field from the response
      return data["result"] == true;
    } catch (e) {
      debugPrint("[Setup] Error checking sheet setup: $e");
      return false;
    }
  }

  Future<void> _callSetupSheetsEndpoint(
      String webAppUrl, String appCode) async {
    int attempts = 0;
    const maxAttempts = 3;
    const timeout = Duration(seconds: 180);

    while (attempts < maxAttempts) {
      try {
        attempts++;
        if (mounted) {
          setState(() => _statusMessage =
              "Initializing sheets (attempt $attempts/$maxAttempts)...");
        }

        final response = await http
            .post(
              Uri.parse(webAppUrl),
              headers: {
                "Content-Type": "application/json",
                ...AppInfoService.instance.httpHeaders,
              },
              body: jsonEncode({
                "secret": appCode,
                "operation": "setupSheets",
              }),
            )
            .timeout(timeout);

        // Handle 302/301 redirects from Google Apps Script
        dynamic data;
        if (response.statusCode == 302 || response.statusCode == 301) {
          final redirectMatch =
              RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
          if (redirectMatch != null) {
            final redirectUrl =
                redirectMatch.group(1)!.replaceAll('&amp;', '&');
            debugPrint("[Setup] Following redirect: $redirectUrl");
            final redirectResponse = await http.get(Uri.parse(redirectUrl));
            // POST → 301/302 → GET loses the request body. For API operations
            // like delta_pull and delta_push, the request body contains critical
            // data (operation type, secret, pagination params, etc.).
            // Converting POST to GET would break these operations
            // However, this might work for Google Apps Script specifically because:
            // Google Apps Script sometimes uses a unique redirect pattern
            // After POST processing, it redirects to a GET endpoint with the
            // JSON result already available
            // The redirect URL might already contain the response data

            if (redirectResponse.statusCode != 200) {
              throw Exception(
                  "HTTP ${redirectResponse.statusCode}: ${redirectResponse.body}");
            }

            data = jsonDecode(redirectResponse.body);
          } else {
            throw Exception("HTTP 302 redirect but no URL found in response");
          }
        } else if (response.statusCode == 200) {
          data = jsonDecode(response.body);
        } else {
          throw Exception("HTTP ${response.statusCode}: ${response.body}");
        }

        if (data["success"] == true) {
          return; // Success!
        } else {
          throw Exception(data["error"] ?? "Setup failed");
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup Google Sheets"),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Google Sign-in Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Step 1: Google Sign-in",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isSignedIn)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSignIn,
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text("Sign in with Google",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Signed in as ${_currentGoogleUser?.email ?? "Unknown"}",
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSignOut,
                                icon: const Icon(Icons.logout,
                                    color: Colors.white),
                                label: const Text("Sign Out from Google",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Choose Google Sheet Section
              if (_isSignedIn)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.table_chart,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              "Choose Google Sheet",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_existingSheetId == null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "No Google Sheet selected yet. Please select or create a sheet.",
                                style: TextStyle(
                                  fontSize: 14,
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.table_chart,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Current Sheet",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _existingSheetName ?? "Loading...",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      "ID: $_existingSheetId",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _isLoading ? null : _changeGoogleSheet,
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                tooltip: "Change Google Sheet",
                              ),
                              IconButton(
                                onPressed:
                                    _isLoading ? null : _deleteGoogleSheet,
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Delete Google Sheet",
                              ),
                              IconButton(
                                onPressed: () async {
                                  final url = Uri.parse(
                                      "https://docs.google.com/spreadsheets/d/$_existingSheetId");
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.open_in_new,
                                    color: Colors.blue),
                                tooltip: "Open in browser",
                              ),
                            ],
                          ),
                        ],
                        if (_existingScriptId != null)
                          const SizedBox(height: 12),
                        if (_existingScriptId != null) const Divider(),
                        if (_existingScriptId != null)
                          const SizedBox(height: 12),
                        if (_existingScriptId != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.code, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Apps Script Project",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _existingScriptName ?? "Loading...",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      "ID: $_existingScriptId",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final url = Uri.parse(
                                      "https://script.google.com/home/projects/$_existingScriptId");
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.open_in_new,
                                    color: Colors.blue),
                                tooltip: "Open in browser",
                              ),
                            ],
                          ),
                        ],
                        if (_isLoadingExistingInfo)
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

              if (_isSignedIn) const SizedBox(height: 16),

              // Step 2: Enable Apps Script API
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            "Step 2: Enable Apps Script API",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "CRITICAL: You must enable the Apps Script API in your Google account settings before proceeding.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SelectableText(
                        "1. Go to: script.google.com/home/usersettings\n"
                        "2. Turn ON the toggle for \"Google Apps Script API\"\n"
                        "3. Come back here and proceed to Step 3",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(
                                "https://script.google.com/home/usersettings");
                            try {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Could not open URL: $e\nPlease visit: script.google.com/home/usersettings"),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.white),
                          label: const Text("Open Settings Page",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Configuration & Deployment Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Step 3: Sheet Creation & Backend Deployment",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sheetNameController,
                        decoration: const InputDecoration(
                          labelText: "Google Sheet Name",
                          hintText: "e.g., Purchase App Data",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        enabled: !_isLoading && !_isDeploymentComplete,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter a sheet name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _appCodeController,
                        decoration: const InputDecoration(
                          labelText: "App Code (Secret)",
                          hintText: "Enter a secure code",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        enabled: !_isLoading && !_isDeploymentComplete,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter an app code";
                          }
                          if (value.trim().length < 8) {
                            return "App code must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ||
                                  !_isSignedIn ||
                                  _isDeploymentComplete ||
                                  _sheetNameController.text.trim().isEmpty ||
                                  _appCodeController.text.trim().isEmpty
                              ? null
                              : _deployBackend,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : _isDeploymentComplete
                                  ? const Icon(Icons.check_circle)
                                  : const Icon(Icons.cloud_upload),
                          label: Text(
                              _isLoading
                                  ? "Deploying..."
                                  : _isDeploymentComplete
                                      ? "Deployment Complete"
                                      : "Deploy Backend",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDeploymentComplete
                                ? Colors.green
                                : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Authenticate Deployed Application
              if (_isDeploymentComplete && _deployedWebAppUrl != null)
                Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Step 4: Authenticate Deployed Application",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "IMPORTANT: You must authorize the deployed app before proceeding.",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SelectableText(
                          "1. Click \"Open Deployed App\" below\n"
                          "2. You will see a Google authorization screen\n"
                          "3. Click \"Advanced\" → \"Go to [your app] (unsafe)\"\n"
                          "4. Review permissions and click \"Allow\"\n"
                          "5. You may see a welcome screen from My Purchase App backend application\n"
                          "6. Come back here and proceed to Step 5",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(_deployedWebAppUrl!);
                              try {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Could not open URL: $e\nPlease copy URL from status section"),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new,
                                color: Colors.white),
                            label: const Text("Open Deployed App",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Setup Sheets Button
              if (_isDeploymentComplete)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Step 5: Setup Sheets",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "After authorizing the app in Step 4, click below to initialize the sheets.",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _setupSheets,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.table_chart),
                            label: Text(
                                _isLoading ? "Setting up..." : "Setup Sheets",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Data Statistics Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _showDataStatistics,
                            icon: const Icon(Icons.analytics,
                                color: Colors.white),
                            label: const Text(
                              "Data Statistics in Sheet",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Step 6: Import Data
              if (_isSheetsSetupComplete)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Step 6: Import Data (Optional)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Choose one of the following options to populate your database with initial data:",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Import from Google Sheet Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _importFromGoogleSheet,
                            icon: const Icon(Icons.cloud_download,
                                color: Colors.white),
                            label: const Text(
                              "Import from Google Sheet",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Import Sample Data Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _importSampleData,
                            icon: const Icon(Icons.folder_open,
                                color: Colors.white),
                            label: const Text(
                              "Import Sample Data",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Import from Zip Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _importFromZipFile,
                            icon:
                                const Icon(Icons.archive, color: Colors.white),
                            label: const Text(
                              "Import Data from Zip File",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "Note: Both options will clear existing data and initialize the change log.",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Step 7: Upload Data to Google Sheets
              if (_isSheetsSetupComplete)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Step 7: Upload Initial Data to Google Sheets",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Upload local SQLite data to Google Sheets to initialize cloud storage.",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Upload Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _uploadDataToGoogleSheets,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload,
                                    color: Colors.white),
                            label: Text(
                              _isLoading
                                  ? "Uploading..."
                                  : "Upload Data to Google Sheets",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Status Section
              if (_statusMessage.isNotEmpty)
                Card(
                  color: _isLoading
                      ? Colors.blue.shade50
                      : _statusMessage.contains("failed")
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_statusMessage.contains("failed"))
                              const Icon(Icons.error, color: Colors.red)
                            else
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                            const SizedBox(width: 12),
                            const Text(
                              "Status",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_statusMessage),
                        if (_deployedWebAppUrl != null) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const Text(
                            "Web App URL:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _deployedWebAppUrl!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
