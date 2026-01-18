# Google Drive File Picker Widget

## Overview

`GoogleDriveFilePicker` is a reusable Flutter widget that provides a comprehensive file selection interface for Google Drive. It supports both hierarchical folder navigation and file search capabilities, making it easy to browse and select files from Google Drive within your Flutter application.

## Features

### 1. Hierarchical Navigation
- **Breadcrumb Navigation**: Visual path showing current location in folder hierarchy
- **Folder Browsing**: Click folders to navigate into them
- **Back Navigation**: Click any breadcrumb to jump back to that folder level
- **Root Start**: Always begins at "My Drive" (root)

### 2. File Search
- **Text Search**: Search files by name across entire Drive
- **Dual Mode**: Automatically switches between browse and search modes
- **Search Results**: Flat list of matching files (no folder navigation)
- **Quick Clear**: Clear button to exit search and return to browse mode
- **MIME Type Filtering**: Search respects MIME type filters

### 3. File Display
- **Visual Icons**: Different icons for different file types (sheets, docs, folders, etc.)
- **Color Coding**: Icon colors vary by file type for easy recognition
- **File Metadata**: Shows file size and last modified date
- **Folder Indicators**: Chevron icon on folders in browse mode
- **Empty States**: Helpful messages when folders are empty or no search results

### 4. Error Handling
- **Error Messages**: Clear error display with retry option
- **Loading States**: Progress indicator during file loading/searching
- **API Error Recovery**: Retry button for failed operations

### 5. Filtering
- **MIME Type Filter**: Optionally restrict to specific file types (e.g., spreadsheets only)
- **Auto-Include Folders**: When MIME filter is set, folders are automatically included for navigation

## Installation

### Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  googleapis: ^13.2.0
  google_sign_in: ^6.2.2
  googleapis_auth: ^1.6.0
  intl: ^0.18.0
```

### Import

```dart
import 'package:purchase_app/widgets/google_drive_file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
```

## Usage

### Basic Example

```dart
// 1. Get authenticated HTTP client
final googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
final account = await googleSignIn.signIn();
final authHeaders = await account!.authHeaders;
final authenticatedClient = auth.authenticatedClient(
  http.Client(),
  auth.AccessCredentials(
    auth.AccessToken('Bearer', authHeaders['Authorization']!.substring(7), DateTime.now().add(Duration(hours: 1))),
    null,
    [],
  ),
);

// 2. Create Drive API instance
final driveApi = drive.DriveApi(authenticatedClient);

// 3. Show file picker dialog
final selectedFileId = await showDialog<String>(
  context: context,
  builder: (context) => GoogleDriveFilePicker(
    driveApi: driveApi,
    title: 'Select a File',
  ),
);

// 4. Use selected file ID
if (selectedFileId != null) {
  print('Selected file ID: $selectedFileId');
  // Fetch file metadata or perform operations
}

// 5. Clean up
authenticatedClient.close();
```

### Filtering by File Type

#### Select Only Google Sheets

```dart
final sheetId = await showDialog<String>(
  context: context,
  builder: (context) => GoogleDriveFilePicker(
    driveApi: driveApi,
    title: 'Select a Google Sheet',
    mimeTypeFilter: 'application/vnd.google-apps.spreadsheet',
  ),
);
```

#### Select Only Files Created by Your App

```dart
import 'package:package_info_plus/package_info_plus.dart';

final packageInfo = await PackageInfo.fromPlatform();

final sheetId = await showDialog<String>(
  context: context,
  builder: (context) => GoogleDriveFilePicker(
    driveApi: driveApi,
    title: 'Select Your App\'s Sheets',
    mimeTypeFilter: 'application/vnd.google-apps.spreadsheet',
    appPackageFilter: packageInfo.packageName, // Filter by app-package
  ),
);
```

#### Select Only Google Docs

```dart
final docId = await showDialog<String>(
  context: context,
  builder: (context) => GoogleDriveFilePicker(
    driveApi: driveApi,
    title: 'Select a Google Document',
    mimeTypeFilter: 'application/vnd.google-apps.document',
  ),
);
```

#### Select PDF Files

```dart
final pdfId = await showDialog<String>(
  context: context,
  builder: (context) => GoogleDriveFilePicker(
    driveApi: driveApi,
    title: 'Select a PDF',
    mimeTypeFilter: 'application/pdf',
  ),
);
```

### Complete Integration Example

```dart
Future<void> _selectGoogleSheet() async {
  try {
    // Get authenticated client
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return;

    final authHeaders = await account.authHeaders;
    final authenticatedClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authHeaders['Authorization']!.substring(7),
          DateTime.now().add(Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      // Create Drive API
      final driveApi = drive.DriveApi(authenticatedClient);

      // Show picker
      final fileId = await showDialog<String>(
        context: context,
        builder: (context) => GoogleDriveFilePicker(
          driveApi: driveApi,
          title: 'Select Google Sheet',
          mimeTypeFilter: 'application/vnd.google-apps.spreadsheet',
        ),
      );

      if (fileId != null) {
        // Get file metadata
        final file = await driveApi.files.get(
          fileId,
          $fields: 'id, name, webViewLink',
        ) as drive.File;

        // Update UI
        setState(() {
          _selectedSheetId = file.id;
          _selectedSheetName = file.name;
          _selectedSheetUrl = file.webViewLink;
        });

        // Save to preferences if needed
        await _saveToSettings(fileId, file.name);
      }
    } finally {
      authenticatedClient.close();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to select file: $e')),
    );
  }
}
```

## API Reference

### Constructor Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `driveApi` | `drive.DriveApi` | Yes | - | Authenticated Google Drive API instance |
| `mimeTypeFilter` | `String?` | No | `null` | Filter files by MIME type (e.g., 'application/vnd.google-apps.spreadsheet') |
| `title` | `String` | No | `'Select File'` | Dialog title text |
| `allowFolderSelection` | `bool` | No | `false` | Allow selecting folders (not yet implemented) |
| `appPackageFilter` | `String?` | No | `null` | Filter files by app-package property value (e.g., 'com.purchase.purchase_app') |

### Return Value

- **Type**: `String?` (via `Navigator.pop`)
- **Value**: Selected file's Google Drive ID, or `null` if cancelled
- **Usage**: Use the returned ID with Drive API to fetch metadata or perform operations

## Supported MIME Types

### Google Workspace Files
- **Spreadsheet**: `application/vnd.google-apps.spreadsheet`
- **Document**: `application/vnd.google-apps.document`
- **Presentation**: `application/vnd.google-apps.presentation`
- **Form**: `application/vnd.google-apps.form`
- **Drawing**: `application/vnd.google-apps.drawing`
- **Folder**: `application/vnd.google-apps.folder`

### Common File Types
- **PDF**: `application/pdf`
- **Image (JPEG)**: `image/jpeg`
- **Image (PNG)**: `image/png`
- **Text**: `text/plain`
- **CSV**: `text/csv`
- **JSON**: `application/json`
- **ZIP**: `application/zip`

For complete list, see [Google Drive MIME Types](https://developers.google.com/drive/api/guides/mime-types).

## User Interface

### Browse Mode
```
┌─────────────────────────────────────┐
│ 🌐 Select Google Sheet          ✕  │
├─────────────────────────────────────┤
│ Search: [___________________] 🔍   │
├─────────────────────────────────────┤
│ My Drive › Documents › Invoices     │
├─────────────────────────────────────┤
│ 📁 2024                          ›  │
│ 📊 Invoice_Jan.xlsx                │
│ 📊 Invoice_Feb.xlsx                │
│ 📁 Templates                     ›  │
├─────────────────────────────────────┤
│                          [Cancel]   │
└─────────────────────────────────────┘
```

### Search Mode
```
┌─────────────────────────────────────┐
│ 🌐 Select Google Sheet          ✕  │
├─────────────────────────────────────┤
│ Search: [invoice_________] ✕       │
├─────────────────────────────────────┤
│ 🔍 Search results for "invoice"     │
│                          [Clear]    │
├─────────────────────────────────────┤
│ 📊 Invoice_Jan.xlsx                │
│ 📊 Invoice_Feb.xlsx                │
│ 📊 Master_Invoice_Template.xlsx    │
├─────────────────────────────────────┤
│                          [Cancel]   │
└─────────────────────────────────────┘
```

## Behavior Details

### Browse Mode
1. **Initial Load**: Starts at "My Drive" (root)
2. **Folder Click**: Navigates into folder, adds to breadcrumbs
3. **File Click**: Returns file ID and closes dialog
4. **Breadcrumb Click**: Jumps to that folder level
5. **MIME Filter**: Shows matching files + all folders

### Search Mode
1. **Enter Search**: Type text and press Enter
2. **Results**: Flat list of matching files (no folders)
3. **MIME Filter**: Applied to search results
4. **No Navigation**: Folders not shown/clickable in results
5. **Clear**: Returns to browse mode at current location
6. **File Click**: Returns file ID and closes dialog

### Error Handling
- **Network Error**: Shows error message with retry button
- **Empty Folder**: "No files in this folder"
- **No Results**: "No files found"
- **API Error**: Displays error text with retry option

## Performance Considerations

- **Search Limit**: Limited to 100 results to prevent performance issues
- **Pagination**: Not currently implemented (consider for large folders)
- **Caching**: No caching - files loaded fresh each navigation
- **Client Cleanup**: Always close `authenticatedClient` after use

## Authentication Requirements

### Required Scopes

```dart
final googleSignIn = GoogleSignIn(
  scopes: [
    drive.DriveApi.driveFileScope,        // Read/write access to files
    // OR
    drive.DriveApi.driveReadonlyScope,    // Read-only access
  ],
);
```

### Token Management
- Access tokens expire (typically 1 hour)
- `google_sign_in` handles token refresh automatically
- Always create fresh `authenticatedClient` for each operation
- Close client after use to free resources

## Limitations

1. **Folder Selection**: `allowFolderSelection` parameter exists but not yet implemented
2. **Pagination**: Large folders show all files (no paging)
3. **Search Debouncing**: Search triggers on Enter only (no auto-search while typing)
4. **Offline Mode**: Requires internet connection (no offline cache)
5. **Multi-Select**: Only single file selection supported
6. **Shared Drives**: Only "My Drive" supported (no Team Drives)

## Future Enhancements

- [ ] Folder selection support
- [ ] Pagination for large folders
- [ ] Search debouncing (auto-search while typing)
- [ ] Multi-file selection
- [ ] Shared/Team Drive support
- [ ] File preview
- [ ] Recent files view
- [ ] Starred files view
- [ ] File upload capability
- [ ] Local caching for offline browsing

## Troubleshooting

### "Failed to load files" Error
- **Cause**: Missing authentication or invalid token
- **Solution**: Ensure user is signed in and has granted Drive scope

### Empty File List
- **Cause**: Folder actually empty, or MIME filter excludes all files
- **Solution**: Check filter, navigate to different folder

### Search Returns Nothing
- **Cause**: No files match search term + MIME filter combination
- **Solution**: Try broader search term or remove MIME filter

### Dialog Doesn't Close on Selection
- **Cause**: `Navigator.pop` not being called
- **Solution**: File selection calls `Navigator.pop(context, file.id)` automatically

## Example: Complete Setup Flow

```dart
class SetupScreen extends StatefulWidget {
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _selectedSheetId;
  String? _selectedSheetName;

  Future<void> _showGoogleDriveFilePicker() async {
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );

    try {
      final account = await googleSignIn.signIn();
      if (account == null) return; // User cancelled sign-in

      final authHeaders = await account.authHeaders;
      final authenticatedClient = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            authHeaders['Authorization']!.substring(7),
            DateTime.now().add(Duration(hours: 1)),
          ),
          null,
          [],
        ),
      );

      try {
        final driveApi = drive.DriveApi(authenticatedClient);

        final fileId = await showDialog<String>(
          context: context,
          builder: (context) => GoogleDriveFilePicker(
            driveApi: driveApi,
            title: 'Select Google Sheet',
            mimeTypeFilter: 'application/vnd.google-apps.spreadsheet',
          ),
        );

        if (fileId != null) {
          // Get file details
          final file = await driveApi.files.get(
            fileId,
            $fields: 'id, name',
          ) as drive.File;

          setState(() {
            _selectedSheetId = file.id;
            _selectedSheetName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: ${file.name}')),
          );
        }
      } finally {
        authenticatedClient.close();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedSheetName != null)
              Text('Selected: $_selectedSheetName'),
            ElevatedButton.icon(
              onPressed: _showGoogleDriveFilePicker,
              icon: Icon(Icons.cloud),
              label: Text('Select Google Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Related Documentation

- [Google Drive API v3](https://developers.google.com/drive/api/v3/reference)
- [googleapis package](https://pub.dev/packages/googleapis)
- [google_sign_in package](https://pub.dev/packages/google_sign_in)
- [Drive API MIME Types](https://developers.google.com/drive/api/guides/mime-types)
- [Drive API Search Query](https://developers.google.com/drive/api/guides/search-files)

## License

This widget is part of the Purchase App project and follows the project's license terms.
