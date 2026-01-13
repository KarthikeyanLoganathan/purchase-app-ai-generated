# Working with Assets in Flutter

## How Flutter Packages Assets

Flutter packages assets through a three-step process:

1. **Declaration in pubspec.yaml** - Assets are listed under the `flutter:` section's `assets:` key
2. **Build-time bundling** - Assets are copied into the app bundle during compilation
3. **Runtime access** - Access via `AssetBundle` APIs (e.g., `rootBundle.loadString()`)

## Current Asset Configuration

In `pubspec.yaml`, the assets section is configured as:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - sample-data/
```

The trailing slash in `sample-data/` means **all files** in the `sample-data/` directory are included in the bundle.

## Adding Additional Asset Directories

To include backend JavaScript files, add them to the assets section:

```yaml
assets:
  - sample-data/
  - backend/google-app-script-code/
```

**Important Notes:**
- Flutter doesn't support wildcards like `*.js` in asset declarations
- When you specify a directory, Flutter includes all files in that directory
- Subdirectories are NOT included recursively unless explicitly listed

## Where Assets Are Packaged in Mobile Apps

### Android
Assets are located at `assets/flutter_assets/` within the APK:
- Example: `assets/flutter_assets/sample-data/currencies.csv`
- Example: `assets/flutter_assets/backend/google-app-script-code/config.js`

### iOS
Assets are inside the app bundle at `Frameworks/App.framework/flutter_assets/`:
- Similar structure: `flutter_assets/sample-data/currencies.csv`

### Accessing Assets in Code
Use the relative path without the `flutter_assets/` prefix:

```dart
String csvData = await rootBundle.loadString('sample-data/currencies.csv');
String jsCode = await rootBundle.loadString('backend/google-app-script-code/config.js');
```

## Iterating Through Files in an Asset Directory

**Problem:** Flutter doesn't provide a built-in way to list/iterate files in an asset directory at runtime.

### Solution 1: Create a Manifest File (Recommended)

Create a JSON file listing all files you want to iterate.

**backend/google-app-script-code/files.json**:
```json
{
  "files": [
    "changeLogUtils.js",
    "cleanup.js",
    "config.js",
    "consistencyChecks.js",
    "constants.js",
    "dataReaders.js",
    "deltaSync.js",
    "deployer.js",
    "exportCSV.js",
    "maintainManufacturerModelData.js",
    "maintainManufacturerModels.js",
    "maintainVendorPriceLists.js",
    "setup.js",
    "sheetEventHandlers.js",
    "tableMetadata.js",
    "utils.js",
    "webSecurity.js",
    "webService.js"
  ]
}
```

**Dart code to load files:**
```dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, String>> loadBackendScripts() async {
  // Load the manifest
  final manifestJson = await rootBundle.loadString(
    'backend/google-app-script-code/files.json'
  );
  final manifest = jsonDecode(manifestJson);
  
  // Load each file
  Map<String, String> scripts = {};
  for (String fileName in manifest['files']) {
    final content = await rootBundle.loadString(
      'backend/google-app-script-code/$fileName'
    );
    scripts[fileName] = content;
  }
  
  return scripts;
}
```

**Advantages:**
- Explicit and maintainable
- Easy to update when you add/remove files
- Doesn't rely on Flutter internals
- Can include metadata about each file

### Solution 2: Hardcode the List

```dart
Future<Map<String, String>> loadBackendScripts() async {
  const fileNames = [
    'changeLogUtils.js',
    'cleanup.js',
    'config.js',
    'consistencyChecks.js',
    'constants.js',
    'dataReaders.js',
    'deltaSync.js',
    'deployer.js',
    'exportCSV.js',
    'maintainManufacturerModelData.js',
    'maintainManufacturerModels.js',
    'maintainVendorPriceLists.js',
    'setup.js',
    'sheetEventHandlers.js',
    'tableMetadata.js',
    'utils.js',
    'webSecurity.js',
    'webService.js',
  ];
  
  Map<String, String> scripts = {};
  for (String fileName in fileNames) {
    final content = await rootBundle.loadString(
      'backend/google-app-script-code/$fileName'
    );
    scripts[fileName] = content;
  }
  
  return scripts;
}
```

**Advantages:**
- Simple and straightforward
- No additional files needed
- Fast to implement

**Disadvantages:**
- Requires code changes when files are added/removed

### Solution 3: Use AssetManifest.bin (Advanced)

**Note:** This approach works but requires decoding binary format. Use with caution.

Access Flutter's asset manifest (handles both .bin and .json formats):

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<List<String>> getJsFiles() async {
  try {
    // Try AssetManifest.bin first (Flutter 3.x+)
    final ByteData manifestData = await rootBundle.load('AssetManifest.bin');
    final manifestList = _decodeAssetManifestBin(manifestData);
    
    final jsFiles = manifestList
        .where((String key) => 
            key.startsWith('backend/google-app-script-code/') && 
            key.endsWith('.js'))
        .toList();
    
    return jsFiles;
  } catch (e) {
    // Fallback to AssetManifest.json (older Flutter)
    final String manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    
    final jsFiles = manifestMap.keys
        .where((String key) => 
            key.startsWith('backend/google-app-script-code/') && 
            key.endsWith('.js'))
        .toList();
    
    return jsFiles;
  }
}

/// Decode AssetManifest.bin format
/// Format: null-terminated UTF-8 strings with variant info
List<String> _decodeAssetManifestBin(ByteData data) {
  final List<String> assets = [];
  final buffer = data.buffer.asUint8List();
  int offset = 0;

  while (offset < buffer.length) {
    // Find the next null terminator
    int end = offset;
    while (end < buffer.length && buffer[end] != 0) {
      end++;
    }

    if (end > offset) {
      // Decode the UTF-8 string
      final assetPath = utf8.decode(buffer.sublist(offset, end));
      if (assetPath.isNotEmpty) {
        assets.add(assetPath);
      }
    }

    // Move past the null terminator
    offset = end + 1;

    // Skip variant data (skip to next null)
    while (offset < buffer.length && buffer[offset] != 0) {
      offset++;
    }
    offset++; // Skip trailing null
  }

  return assets;
}
```

**Advantages:**
- ✅ Automatically discovers all assets
- ✅ Works with Flutter 3.x+ (binary format)
- ✅ Falls back to JSON for older versions
- ✅ No need to maintain a separate list

**Disadvantages:**
- ⚠️ Relies on Flutter internal format (could change)
- ⚠️ Binary decoding is custom implementation
- ⚠️ More complex than manifest file approach
- ⚠️ Less explicit about what files are expected

**When to Use:**
- You have many dynamic assets
- Asset list changes frequently
- You want automatic discovery

**When NOT to Use:**
- Small, stable set of assets → Use Solution 1
- Production-critical code → Use Solution 1
- Need maximum reliability → Use Solution 1

## Best Practices

1. **Use manifest files** for dynamic asset loading - more maintainable
2. **Keep asset paths relative** - don't hardcode absolute paths
3. **Test asset loading** on both Android and iOS
4. **Consider asset size** - large assets increase app size
5. **Use appropriate async patterns** - asset loading is asynchronous
6. **Handle missing assets gracefully** - catch exceptions when loading

## Common Issues

### Asset not found error
```dart
// Bad - missing from pubspec.yaml
await rootBundle.loadString('missing/file.txt'); // Throws exception

// Good - handle potential errors
try {
  final content = await rootBundle.loadString('sample-data/currencies.csv');
} catch (e) {
  print('Failed to load asset: $e');
}
```

### Case sensitivity
Asset paths are case-sensitive. `sample-data/file.txt` ≠ `sample-data/file.txt`

### Trailing slashes matter
- `assets/images/` - includes all files in the images directory
- `assets/images` - refers to a file named "images" (likely not what you want)
