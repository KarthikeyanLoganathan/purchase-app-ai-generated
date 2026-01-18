# How to Get Application Package Information in Flutter

## Overview

The `package_info_plus` package provides a cross-platform way to retrieve application metadata such as package name, app name, version, and build number at runtime. This is essential for features like:

- Tagging files with app identity (Google Drive app properties)
- Displaying app version in About screen
- Analytics and crash reporting
- Feature flags based on version
- API requests requiring app identification

## Installation

### Add Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  package_info_plus: ^8.0.0
```

### Install

```bash
flutter pub get
```

## Basic Usage

### Get Package Information

```dart
import 'package:package_info_plus/package_info_plus.dart';

Future<void> getAppInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  
  print('Package name: ${packageInfo.packageName}');  // com.purchase.purchase_app
  print('App name: ${packageInfo.appName}');          // purchase_app
  print('Version: ${packageInfo.version}');           // 1.0.0
  print('Build number: ${packageInfo.buildNumber}');  // 1
}
```

### Available Properties

```dart
final info = await PackageInfo.fromPlatform();

// Package/Bundle identifier
String packageName = info.packageName;
// Android: com.purchase.purchase_app
// iOS: com.purchase.purchaseApp

// App display name
String appName = info.appName;
// Both: purchase_app

// Version string (from pubspec.yaml)
String version = info.version;
// Both: 1.0.0

// Build number (from pubspec.yaml)
String buildNumber = info.buildNumber;
// Both: 1

// Build signature (Android only, empty on iOS)
String buildSignature = info.buildSignature;
// Android: APK/AAB signing SHA

// Installer store (where app was installed from)
String? installerStore = info.installerStore;
// Android: com.android.vending (Play Store), null (sideload)
// iOS: com.apple.AppStore, com.apple.TestFlight, null (dev)
```

## Common Use Cases

### 1. Display App Version in UI

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  String _packageName = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
      _packageName = info.packageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 48,
            child: Icon(Icons.shopping_cart, size: 48),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Purchase App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_version (Build $_buildNumber)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _packageName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text('$_version ($_buildNumber)'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Package Name'),
            subtitle: Text(_packageName),
          ),
        ],
      ),
    );
  }
}
```

### 2. Tag Google Drive Files with App Identity

```dart
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:package_info_plus/package_info_plus.dart';

Future<String> createTaggedSheet(
  drive.DriveApi driveApi,
  String sheetName,
) async {
  // Get app information
  final packageInfo = await PackageInfo.fromPlatform();
  
  // Create sheet with app properties
  final file = drive.File()
    ..name = sheetName
    ..mimeType = 'application/vnd.google-apps.spreadsheet'
    ..description = 'Created by ${packageInfo.appName}'
    ..appProperties = {
      'app-package': packageInfo.packageName,      // Unique app identifier
      'app-name': packageInfo.appName,             // Display name
      'app-version': packageInfo.version,          // Version for compatibility
      'app-build': packageInfo.buildNumber,        // Build number
      'created-at': DateTime.now().toIso8601String(),
    };
  
  final created = await driveApi.files.create(
    file,
    $fields: 'id, name',
  );
  
  print('Created sheet ${created.name} with app tag: ${packageInfo.packageName}');
  return created.id!;
}

// Search for files created by this app
Future<List<drive.File>> findAppFiles(drive.DriveApi driveApi) async {
  final packageInfo = await PackageInfo.fromPlatform();
  
  final query = "appProperties has { key='app-package' and value='${packageInfo.packageName}' } "
                "and trashed=false";
  
  final result = await driveApi.files.list(
    q: query,
    $fields: 'files(id, name, appProperties, modifiedTime)',
    orderBy: 'modifiedTime desc',
  );
  
  return result.files ?? [];
}
```

### 3. Version-Based Feature Flags

```dart
import 'package:package_info_plus/package_info_plus.dart';

class FeatureFlags {
  static PackageInfo? _packageInfo;
  
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  static bool get isNewDashboardEnabled {
    if (_packageInfo == null) return false;
    
    final version = _packageInfo!.version;
    final parts = version.split('.');
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    
    // Enable for version 2.0 and above
    return major >= 2;
  }
  
  static bool get isExperimentalSyncEnabled {
    if (_packageInfo == null) return false;
    
    // Enable for beta builds (build number > 100)
    final buildNumber = int.tryParse(_packageInfo!.buildNumber) ?? 0;
    return buildNumber > 100;
  }
}

// Usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FeatureFlags.initialize();
  
  runApp(MyApp());
}

// Usage in widgets
if (FeatureFlags.isNewDashboardEnabled) {
  return NewDashboard();
} else {
  return LegacyDashboard();
}
```

### 4. API Requests with App Identification

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ApiClient {
  static PackageInfo? _packageInfo;
  
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    if (_packageInfo == null) {
      await initialize();
    }
    
    return http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': '${_packageInfo!.appName}/${_packageInfo!.version}',
        'X-App-Package': _packageInfo!.packageName,
        'X-App-Version': _packageInfo!.version,
        'X-App-Build': _packageInfo!.buildNumber,
      },
      body: jsonEncode(body),
    );
  }
}

// Backend can identify app and version
// POST /api/sync
// User-Agent: purchase_app/1.0.0
// X-App-Package: com.purchase.purchase_app
// X-App-Version: 1.0.0
// X-App-Build: 1
```

### 5. Analytics Integration

```dart
import 'package:package_info_plus/package_info_plus.dart';

class Analytics {
  static Future<void> initialize() async {
    final info = await PackageInfo.fromPlatform();
    
    // Send app context with every event
    setUserProperties({
      'app_name': info.appName,
      'app_version': info.version,
      'app_build': info.buildNumber,
      'app_package': info.packageName,
    });
  }
  
  static void logEvent(String eventName, Map<String, dynamic> parameters) {
    // Include app info in every event
    // Firebase/Mixpanel/Custom analytics
  }
}
```

### 6. Crash Reporting Context

```dart
import 'package:package_info_plus/package_info_plus.dart';

class CrashReporting {
  static Future<void> initialize() async {
    final info = await PackageInfo.fromPlatform();
    
    // Set crash report metadata
    setCrashMetadata({
      'app_version': info.version,
      'app_build': info.buildNumber,
      'package_name': info.packageName,
    });
  }
  
  static void reportError(dynamic error, StackTrace stackTrace) {
    // Error reports will include app version info
  }
}
```

## Platform-Specific Details

### Android

**Package Name Source**: Defined in `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.purchase.purchase_app"
    
    defaultConfig {
        applicationId = "com.purchase.purchase_app"
        // ...
    }
}
```

**Version Source**: From `pubspec.yaml` (synced during build)

```yaml
version: 1.0.0+1
```

**Build Signature**: SHA-256 of the APK/AAB signing certificate

**Installer Store Examples**:
- `com.android.vending` - Google Play Store
- `com.amazon.venezia` - Amazon Appstore
- `null` - Sideloaded APK

### iOS

**Package Name Source**: Bundle Identifier in `ios/Runner.xcodeproj/project.pbxproj`

```
PRODUCT_BUNDLE_IDENTIFIER = com.purchase.purchaseApp;
```

**Note**: iOS typically uses camelCase (`purchaseApp`) vs Android's snake_case (`purchase_app`)

**Version Source**: From `pubspec.yaml` (synced via Flutter build)

**Build Signature**: Empty string on iOS

**Installer Store Examples**:
- `com.apple.AppStore` - App Store
- `com.apple.TestFlight` - TestFlight
- `null` - Development build

## Property Comparison Table

| Property | Android Example | iOS Example | Source |
|----------|----------------|-------------|--------|
| `packageName` | `com.purchase.purchase_app` | `com.purchase.purchaseApp` | Build config |
| `appName` | `purchase_app` | `purchase_app` | App label/display name |
| `version` | `1.0.0` | `1.0.0` | pubspec.yaml |
| `buildNumber` | `1` | `1` | pubspec.yaml |
| `buildSignature` | SHA-256 hash | Empty string | Signing certificate |
| `installerStore` | Play Store package | App Store ID or null | Platform API |

## Complete Integration Example

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static AppInfoService? _instance;
  static AppInfoService get instance {
    _instance ??= AppInfoService._();
    return _instance!;
  }
  
  AppInfoService._();
  
  PackageInfo? _packageInfo;
  
  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    print('App initialized: ${_packageInfo!.packageName} v${_packageInfo!.version}');
  }
  
  String get packageName => _packageInfo?.packageName ?? 'unknown';
  String get appName => _packageInfo?.appName ?? 'Unknown App';
  String get version => _packageInfo?.version ?? '0.0.0';
  String get buildNumber => _packageInfo?.buildNumber ?? '0';
  String get fullVersion => '$version+$buildNumber';
  
  Map<String, String> get appProperties => {
    'app-package': packageName,
    'app-name': appName,
    'app-version': version,
    'app-build': buildNumber,
  };
  
  bool isVersionAtLeast(String requiredVersion) {
    final current = version.split('.').map(int.tryParse).toList();
    final required = requiredVersion.split('.').map(int.tryParse).toList();
    
    for (int i = 0; i < 3; i++) {
      final currentPart = i < current.length ? (current[i] ?? 0) : 0;
      final requiredPart = i < required.length ? (required[i] ?? 0) : 0;
      
      if (currentPart > requiredPart) return true;
      if (currentPart < requiredPart) return false;
    }
    
    return true; // Equal
  }
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app info
  await AppInfoService.instance.initialize();
  
  runApp(MyApp());
}

// Usage throughout app
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appInfo = AppInfoService.instance;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(appInfo.fullVersion),
          ),
          ListTile(
            title: const Text('Package Name'),
            subtitle: Text(appInfo.packageName),
          ),
          if (appInfo.isVersionAtLeast('2.0.0'))
            ListTile(
              title: const Text('New Feature'),
              subtitle: const Text('Available in v2.0+'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
        ],
      ),
    );
  }
}
```

## Best Practices

### 1. Initialize Early

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get package info once at startup
  final packageInfo = await PackageInfo.fromPlatform();
  
  // Pass to app or store in service
  runApp(MyApp(packageInfo: packageInfo));
}
```

### 2. Cache the Result

```dart
class AppInfo {
  static PackageInfo? _cached;
  
  static Future<PackageInfo> get() async {
    _cached ??= await PackageInfo.fromPlatform();
    return _cached!;
  }
}

// Usage
final info = await AppInfo.get(); // Fast after first call
```

### 3. Use for Drive File Tagging

```dart
// Always tag files with package name for reliable identification
final packageInfo = await PackageInfo.fromPlatform();

final file = drive.File()
  ..appProperties = {
    'app-package': packageInfo.packageName,  // Unique identifier
    'app-version': packageInfo.version,      // For compatibility checks
  };
```

### 4. Version Comparison Helper

```dart
class VersionHelper {
  static int compare(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();
    
    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      
      if (p1 != p2) return p1.compareTo(p2);
    }
    
    return 0;
  }
  
  static bool isAtLeast(String current, String required) {
    return compare(current, required) >= 0;
  }
}

// Usage
if (VersionHelper.isAtLeast(info.version, '2.1.0')) {
  // Enable feature
}
```

## Troubleshooting

### Package Name is Empty/Null

**Problem**: `packageName` returns empty string

**Solution**: 
- Android: Check `applicationId` in `android/app/build.gradle.kts`
- iOS: Check `PRODUCT_BUNDLE_IDENTIFIER` in Xcode project
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`

### Version Doesn't Update

**Problem**: Version still shows old value after changing `pubspec.yaml`

**Solution**:
```bash
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

### Different Package Names on Android/iOS

**Android**: `com.purchase.purchase_app` (snake_case)
**iOS**: `com.purchase.purchaseApp` (camelCase)

**Solution**: Normalize when comparing:
```dart
final normalizedPackage = packageName.toLowerCase().replaceAll('_', '');
```

Or use a common prefix and ignore suffix differences.

### Web Support

`package_info_plus` supports web, but has limitations:

```dart
// On web
final info = await PackageInfo.fromPlatform();
// packageName: Returns empty string on web
// version: From pubspec.yaml
// buildNumber: From pubspec.yaml
```

Use fallbacks for web:
```dart
final packageName = info.packageName.isEmpty 
    ? 'com.purchase.purchase_app' 
    : info.packageName;
```

## Related Documentation

- [package_info_plus on pub.dev](https://pub.dev/packages/package_info_plus)
- [Android Application ID](https://developer.android.com/build/configure-app-module#set-application-id)
- [iOS Bundle Identifier](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleidentifier)
- [Flutter Version Management](https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration)

## Summary

Use `package_info_plus` to:
- ✅ Get package/bundle identifier dynamically
- ✅ Display app version in UI
- ✅ Tag Google Drive files with app identity
- ✅ Send app info to analytics/APIs
- ✅ Implement version-based feature flags
- ✅ Add context to crash reports

**Key Points**:
- Cross-platform (Android, iOS, Web, macOS, Windows, Linux)
- Reads from platform-specific configuration files
- Version/build number from `pubspec.yaml`
- Package name may differ slightly between Android/iOS
- Cache result for performance
- Initialize early in app lifecycle
