# Automated Google Sheets Backend Setup from Flutter App

## Overview

Automating the Google Sheets + Apps Script setup from the Flutter app would significantly improve the user experience by eliminating manual backend configuration.

## Architecture Overview

**Flow:**
1. User signs in with Google OAuth2 in Flutter app
2. App creates Google Sheet using Sheets API
3. App deploys Apps Script using Apps Script API
4. App auto-configures itself with the deployment URL

## Implementation Steps

### 1. Add Google OAuth2 Authentication

**Dependencies needed:**
```yaml
dependencies:
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
  googleapis_auth: ^1.6.0
  http: ^1.2.0
```

**Required OAuth Scopes:**
- `https://www.googleapis.com/auth/spreadsheets` - Create/manage sheets
- `https://www.googleapis.com/auth/script.projects` - Deploy Apps Script
- `https://www.googleapis.com/auth/drive.file` - Access created files

### 2. Create Automated Setup Service

Create `lib/services/google_backend_setup_service.dart`:

```dart
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/script/v1.dart' as script;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleBackendSetupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/script.projects',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  Future<SetupResult> autoSetupBackend() async {
    // 1. Sign in user
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Sign in cancelled');
    
    final auth = await account.authentication;
    final credentials = auth.AccessCredentials(
      auth.AccessToken('Bearer', auth.accessToken!, DateTime.now().add(Duration(hours: 1))),
      null,
      [/* scopes */],
    );
    
    final client = auth.authenticatedClient(httpClient, credentials);
    
    // 2. Create Google Sheet
    final spreadsheetId = await _createSpreadsheet(client);
    
    // 3. Setup sheet structure
    await _setupSheetStructure(client, spreadsheetId);
    
    // 4. Deploy Apps Script
    final scriptId = await _createAppsScript(client, spreadsheetId);
    
    // 5. Deploy as web app
    final webAppUrl = await _deployWebApp(client, scriptId);
    
    // 6. Generate and store secret code
    final secretCode = _generateSecretCode();
    await _storeConfig(client, spreadsheetId, secretCode);
    
    return SetupResult(
      spreadsheetId: spreadsheetId,
      webAppUrl: webAppUrl,
      secretCode: secretCode,
    );
  }

  Future<String> _createSpreadsheet(HttpClient client) async {
    final sheetsApi = sheets.SheetsApi(client);
    
    final spreadsheet = sheets.Spreadsheet()
      ..properties = (sheets.SpreadsheetProperties()
        ..title = 'Purchase App - ${DateTime.now().toString()}');
    
    final created = await sheetsApi.spreadsheets.create(spreadsheet);
    return created.spreadsheetId!;
  }

  Future<void> _setupSheetStructure(HttpClient client, String spreadsheetId) async {
    final sheetsApi = sheets.SheetsApi(client);
    
    // Create all required sheets
    final requests = [
      _createSheetRequest('config'),
      _createSheetRequest('change_log'),
      _createSheetRequest('currencies'),
      _createSheetRequest('manufacturers'),
      _createSheetRequest('vendors'),
      _createSheetRequest('materials'),
      _createSheetRequest('manufacturer_materials'),
      _createSheetRequest('vendor_price_lists'),
      _createSheetRequest('purchase_orders'),
      _createSheetRequest('purchase_order_items'),
      // ... add all other tables
    ];
    
    await sheetsApi.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest()..requests = requests,
      spreadsheetId,
    );
  }

  Future<String> _createAppsScript(HttpClient client, String spreadsheetId) async {
    final scriptApi = script.ScriptApi(client);
    
    // Read your Apps Script code from assets or embed it
    final scriptContent = await _loadAppsScriptCode();
    
    final project = script.CreateProjectRequest()
      ..title = 'Purchase App Backend'
      ..parentId = spreadsheetId;
    
    final created = await scriptApi.projects.create(project);
    
    // Upload script files
    await scriptApi.projects.updateContent(
      script.Content()..files = [
        script.File()
          ..name = 'Code'
          ..type = 'SERVER_JS'
          ..source = scriptContent,
        script.File()
          ..name = 'appsscript'
          ..type = 'JSON'
          ..source = _getAppsScriptManifest(),
      ],
      created.scriptId!,
    );
    
    return created.scriptId!;
  }

  Future<String> _deployWebApp(HttpClient client, String scriptId) async {
    final scriptApi = script.ScriptApi(client);
    
    // Create deployment
    final deployment = script.DeploymentConfig()
      ..scriptId = scriptId
      ..description = 'Purchase App API'
      ..manifestFileName = 'appsscript';
    
    final deployed = await scriptApi.projects.deployments.create(
      deployment,
      scriptId,
    );
    
    return deployed.entryPoints!
      .firstWhere((e) => e.entryPointType == 'WEB_APP')
      .webApp!
      .url!;
  }

  String _generateSecretCode() {
    // Generate a secure random code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _storeConfig(HttpClient client, String spreadsheetId, String code) async {
    final sheetsApi = sheets.SheetsApi(client);
    
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange()..values = [['APP_CODE', code]],
      spreadsheetId,
      'config!A1:B1',
      valueInputOption: 'RAW',
    );
  }
}

class SetupResult {
  final String spreadsheetId;
  final String webAppUrl;
  final String secretCode;
  
  SetupResult({required this.spreadsheetId, required this.webAppUrl, required this.secretCode});
}
```

### 3. Bundle Apps Script Code

Store the Apps Script code in assets or as a string:

```dart
Future<String> _loadAppsScriptCode() async {
  // Option 1: Load from assets
  return await rootBundle.loadString('assets/backend/Code.js');
  
  // Option 2: Embed directly (less maintainable)
  return '''
    function doPost(e) {
      // Your Apps Script code here
    }
  ''';
}

String _getAppsScriptManifest() {
  return jsonEncode({
    "timeZone": "America/New_York",
    "dependencies": {},
    "exceptionLogging": "STACKDRIVER",
    "runtimeVersion": "V8",
    "webapp": {
      "access": "ANYONE",
      "executeAs": "USER_DEPLOYING"
    }
  });
}
```

### 4. Add Setup UI to Login Screen

Modify `lib/screens/login_screen.dart`:

```dart
ElevatedButton(
  onPressed: () async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Setting up your backend...'),
            ],
          ),
        ),
      );
      
      final setupService = GoogleBackendSetupService();
      final result = await setupService.autoSetupBackend();
      
      // Auto-configure the app
      await DeltaSyncService.instance.saveCredentials(
        result.webAppUrl,
        result.secretCode,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      // Show success and spreadsheet link
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Setup Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your backend is ready!'),
              SizedBox(height: 16),
              Text('Spreadsheet ID: ${result.spreadsheetId}'),
              ElevatedButton(
                onPressed: () {
                  // Open spreadsheet in browser
                  launchUrl('https://docs.google.com/spreadsheets/d/${result.spreadsheetId}');
                },
                child: Text('View Spreadsheet'),
              ),
            ],
          ),
        ),
      );
      
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog(context, e.toString());
    }
  },
  child: Text('Auto Setup with Google'),
)
```

### 5. Alternative: Template-Based Approach (Simpler)

If the Apps Script API is too complex, use a simpler approach:

#### Step 1: Host a template spreadsheet publicly

Create a public template with the Apps Script already configured.

#### Step 2: User copies it via Sheets API

```dart
Future<String> copyTemplateSheet() async {
  final driveApi = drive.DriveApi(client);
  
  final copy = await driveApi.files.copy(
    drive.File()..name = 'My Purchase App Backend',
    TEMPLATE_SPREADSHEET_ID,
  );
  
  return copy.id!;
}
```

#### Step 3: User manually deploys

The user performs a one-click deployment of the already-included Apps Script directly from the copied spreadsheet.

## Key Considerations

### Limitations

⚠️ **Challenges:**
- Apps Script API requires additional OAuth setup in Google Cloud Console
- Deployment might require user to authorize the script in browser once
- Template approach is simpler but less automated
- Google Cloud Project setup needed for OAuth
- Apps Script quota limits may apply

### Benefits

✅ **Advantages:**
- One-click backend setup
- No manual spreadsheet configuration
- Auto-generated secure credentials
- Better onboarding UX
- Reduced user errors
- Faster time to first sync

## Recommended Approach

**Hybrid Approach:**

1. **Phase 1**: Template-based (Easier to implement)
   - Host public template spreadsheet
   - User copies via Drive API
   - User manually deploys script (one button click)
   - 90% automated, minimal complexity

2. **Phase 2**: Full automation (Future enhancement)
   - Implement full Apps Script API integration
   - Auto-deploy web app
   - 100% automated, zero manual steps

## Implementation Checklist

- [ ] Set up Google Cloud Project
- [ ] Configure OAuth consent screen
- [ ] Add required OAuth scopes
- [ ] Add googleapis dependencies
- [ ] Implement Google Sign-In
- [ ] Create backend setup service
- [ ] Bundle Apps Script code
- [ ] Add UI for automated setup
- [ ] Test end-to-end flow
- [ ] Document setup process
- [ ] Handle error cases
- [ ] Add loading indicators
- [ ] Test with different Google accounts

## Next Steps

1. Decide between template-based vs full automation approach
2. Create Google Cloud Project with proper OAuth configuration
3. Implement the chosen approach
4. Test thoroughly with real Google accounts
5. Update documentation with new setup flow
