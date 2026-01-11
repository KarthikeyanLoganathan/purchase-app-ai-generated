import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import '../services/export_import_service.dart';
import '../utils/settings_manager.dart';

/// Dialog for uploading data to Google Sheets
class UploadToGoogleSheetDialog extends StatefulWidget {
  const UploadToGoogleSheetDialog({super.key});

  @override
  State<UploadToGoogleSheetDialog> createState() =>
      _UploadToGoogleSheetDialogState();
}

class _UploadToGoogleSheetDialogState extends State<UploadToGoogleSheetDialog> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive',
    ],
  );

  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _currentGoogleUser = account;
        });
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
      setState(() {
        _isLoading = true;
        _statusMessage = 'Signing in to Google...';
      });

      await _googleSignIn.signIn();

      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign-in failed: $e';
      });

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
    setState(() {
      _statusMessage = '';
    });
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

  Future<void> _uploadToGoogleSheets() async {
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

    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading data to Google Sheets...';
    });

    try {
      final client = await _getAuthenticatedClient();

      final exportImportService = ExportImportService();
      final result = await exportImportService.uploadDataToGoogleSheets(
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
      final totalRecordsUploaded = result['recordsUploaded'] ?? 0;

      setState(() {
        _isUploading = false;
        _statusMessage = 'Upload completed!\n'
            'Tables processed: $totalTablesProcessed\n'
            'Records uploaded: $totalRecordsUploaded';
      });

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

        // Close dialog after successful upload
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Upload failed: $e';
      });

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload to Google Sheets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google Sign-In Section
            if (_currentGoogleUser == null) ...[
              const Text(
                'Please sign in to Google to upload data:',
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
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadToGoogleSheets,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload, color: Colors.white),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Upload Data',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
          onPressed: _isUploading
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
