# Google Drive Custom App Properties

## Overview

Google Drive API supports custom metadata that you can attach to files (including Google Sheets) for tagging, categorization, and efficient searching. This is essential for apps that create and manage multiple Drive files and need to identify which files belong to the app.

## Two Types of Custom Properties

### 1. App Properties (Recommended)
- **Visibility**: Private to your application
- **Use Case**: Internal app metadata, tagging, categorization
- **Security**: Other apps cannot see or modify these properties
- **Best For**: Identifying files created/managed by your app

### 2. Public Properties
- **Visibility**: Visible to all applications
- **Use Case**: Cross-app metadata sharing
- **Security**: Any app with access can see and modify
- **Best For**: Interoperability between apps

## Why Use App Properties?

1. **Reliable File Identification**: Find files created by your app even if users rename them
2. **Efficient Searching**: Query by metadata instead of filename patterns
3. **Version Management**: Track schema versions for data migration
4. **Metadata Storage**: Store app-specific configuration without modifying file content
5. **Privacy**: Properties are invisible to users and other apps

## Creating Files with App Properties

### Basic Example: Create Tagged Google Sheet

```dart
import 'package:googleapis/drive/v3.dart' as drive;

Future<String> createTaggedSheet(
  drive.DriveApi driveApi,
  String sheetName,
) async {
  final file = drive.File()
    ..name = sheetName
    ..mimeType = 'application/vnd.google-apps.spreadsheet'
    ..appProperties = {
      'app': 'my-purchase-app',
      'type': 'purchase-tracking',
      'version': '1.0',
    };

  final createdFile = await driveApi.files.create(
    file,
    $fields: 'id, name, appProperties',
  );

  print('Created sheet: ${createdFile.name} (${createdFile.id})');
  print('App properties: ${createdFile.appProperties}');
  
  return createdFile.id!;
}
```

### Advanced Example: Complete Metadata

```dart
Future<String> createPurchaseSheet({
  required drive.DriveApi driveApi,
  required String sheetName,
  String? parentFolderId,
}) async {
  final file = drive.File()
    ..name = sheetName
    ..mimeType = 'application/vnd.google-apps.spreadsheet'
    ..description = 'Purchase tracking sheet created by My Purchase App'
    ..appProperties = {
      // App identification
      'app': 'my-purchase-app',
      'app-version': '1.2.0',
      
      // Purpose and type
      'purpose': 'purchase-tracking',
      'sheet-type': 'master-data',
      
      // Schema version for data migration
      'data-schema-version': '2.1',
      
      // Creation metadata
      'created-by': 'api',
      'created-at': DateTime.now().toIso8601String(),
      
      // Configuration flags
      'auto-sync-enabled': 'true',
      'backend-deployed': 'false',
      
      // User identification (if needed)
      'created-by-user': 'user@example.com',
    };

  // Add parent folder if specified
  if (parentFolderId != null) {
    file.parents = [parentFolderId];
  }

  final createdFile = await driveApi.files.create(
    file,
    $fields: 'id, name, webViewLink, appProperties, createdTime',
  );

  return createdFile.id!;
}
```

## Updating App Properties

### Update Existing File's Properties

```dart
Future<void> updateAppProperties(
  drive.DriveApi driveApi,
  String fileId,
  Map<String, String> propertiesToUpdate,
) async {
  final file = drive.File()
    ..appProperties = propertiesToUpdate;

  await driveApi.files.update(
    file,
    fileId,
    $fields: 'appProperties',
  );
}

// Usage example
await updateAppProperties(
  driveApi,
  sheetId,
  {
    'backend-deployed': 'true',
    'deployment-url': 'https://script.google.com/...',
    'deployed-at': DateTime.now().toIso8601String(),
  },
);
```

### Add Properties Without Removing Existing Ones

```dart
Future<void> addAppProperties(
  drive.DriveApi driveApi,
  String fileId,
  Map<String, String> newProperties,
) async {
  // First, get existing properties
  final existingFile = await driveApi.files.get(
    fileId,
    $fields: 'appProperties',
  ) as drive.File;

  // Merge with new properties
  final mergedProperties = {
    ...?existingFile.appProperties,
    ...newProperties,
  };

  // Update with merged properties
  final file = drive.File()..appProperties = mergedProperties;
  
  await driveApi.files.update(file, fileId);
}
```

### Remove Specific Properties

```dart
Future<void> removeAppProperty(
  drive.DriveApi driveApi,
  String fileId,
  String propertyKey,
) async {
  // Get existing properties
  final existingFile = await driveApi.files.get(
    fileId,
    $fields: 'appProperties',
  ) as drive.File;

  // Remove the specific key
  final updatedProperties = Map<String, String>.from(
    existingFile.appProperties ?? {},
  )..remove(propertyKey);

  // Update file
  final file = drive.File()..appProperties = updatedProperties;
  await driveApi.files.update(file, fileId);
}
```

## Searching by App Properties

### Basic Search: Find All App's Files

```dart
Future<List<drive.File>> findMyAppFiles(drive.DriveApi driveApi) async {
  final query = "appProperties has { key='app' and value='my-purchase-app' } "
                "and trashed=false";

  final fileList = await driveApi.files.list(
    q: query,
    spaces: 'drive',
    $fields: 'files(id, name, appProperties, createdTime, webViewLink)',
    orderBy: 'createdTime desc',
  );

  return fileList.files ?? [];
}
```

### Advanced Search: Multiple Conditions

```dart
Future<List<drive.File>> findPurchaseSheets({
  required drive.DriveApi driveApi,
  String? schemaVersion,
  bool? backendDeployed,
}) async {
  // Base query - find all sheets from this app
  String query = "appProperties has { key='app' and value='my-purchase-app' } "
                 "and mimeType='application/vnd.google-apps.spreadsheet' "
                 "and trashed=false";

  // Add schema version filter
  if (schemaVersion != null) {
    query += " and appProperties has { key='data-schema-version' and value='$schemaVersion' }";
  }

  // Add deployment status filter
  if (backendDeployed != null) {
    final deployedValue = backendDeployed ? 'true' : 'false';
    query += " and appProperties has { key='backend-deployed' and value='$deployedValue' }";
  }

  final fileList = await driveApi.files.list(
    q: query,
    spaces: 'drive',
    $fields: 'files(id, name, appProperties, modifiedTime, webViewLink)',
    orderBy: 'modifiedTime desc',
  );

  return fileList.files ?? [];
}

// Usage examples
final allSheets = await findPurchaseSheets(driveApi: driveApi);
final v2Sheets = await findPurchaseSheets(driveApi: driveApi, schemaVersion: '2.1');
final deployedSheets = await findPurchaseSheets(driveApi: driveApi, backendDeployed: true);
```

### Search by Multiple Property Values

```dart
Future<List<drive.File>> findSheetsByType(
  drive.DriveApi driveApi,
  List<String> types,
) async {
  // For multiple values, you need separate queries
  final allFiles = <drive.File>[];
  
  for (final type in types) {
    final query = "appProperties has { key='app' and value='my-purchase-app' } "
                  "and appProperties has { key='sheet-type' and value='$type' } "
                  "and trashed=false";
    
    final result = await driveApi.files.list(
      q: query,
      $fields: 'files(id, name, appProperties)',
    );
    
    allFiles.addAll(result.files ?? []);
  }
  
  return allFiles;
}

// Usage
final sheets = await findSheetsByType(
  driveApi,
  ['master-data', 'archive', 'backup'],
);
```

### Check if File Has Specific Properties

```dart
Future<bool> isMyAppFile(drive.DriveApi driveApi, String fileId) async {
  final file = await driveApi.files.get(
    fileId,
    $fields: 'appProperties',
  ) as drive.File;

  return file.appProperties?['app'] == 'my-purchase-app';
}

Future<String?> getFileSchemaVersion(
  drive.DriveApi driveApi,
  String fileId,
) async {
  final file = await driveApi.files.get(
    fileId,
    $fields: 'appProperties',
  ) as drive.File;

  return file.appProperties?['data-schema-version'];
}
```

## Common Use Cases

### 1. File Identification and Ownership

```dart
// Tag files on creation
final file = drive.File()
  ..name = 'Purchase Data'
  ..mimeType = 'application/vnd.google-apps.spreadsheet'
  ..appProperties = {
    'app': 'my-purchase-app',
    'created-by': 'api',
  };

// Later, find all your app's files
final myFiles = await driveApi.files.list(
  q: "appProperties has { key='app' and value='my-purchase-app' }",
);
```

### 2. Version Management and Migration

```dart
// Create file with schema version
final file = drive.File()
  ..name = 'Data Sheet'
  ..appProperties = {
    'app': 'my-purchase-app',
    'data-schema-version': '2.0',
  };

// Find files that need migration
final oldVersionFiles = await driveApi.files.list(
  q: "appProperties has { key='app' and value='my-purchase-app' } "
     "and appProperties has { key='data-schema-version' and value='1.0' }",
);

// Migrate each file
for (final oldFile in oldVersionFiles.files ?? []) {
  await migrateFileSchema(oldFile.id!, from: '1.0', to: '2.0');
  
  // Update version tag
  await updateAppProperties(
    driveApi,
    oldFile.id!,
    {'data-schema-version': '2.0'},
  );
}
```

### 3. Configuration and State Management

```dart
// Store configuration in properties
await updateAppProperties(driveApi, sheetId, {
  'auto-sync-enabled': 'true',
  'sync-interval-minutes': '30',
  'last-sync-time': DateTime.now().toIso8601String(),
  'backend-deployed': 'true',
  'backend-url': 'https://script.google.com/macros/s/...',
});

// Read configuration
final file = await driveApi.files.get(
  sheetId,
  $fields: 'appProperties',
) as drive.File;

final autoSync = file.appProperties?['auto-sync-enabled'] == 'true';
final syncInterval = int.parse(file.appProperties?['sync-interval-minutes'] ?? '60');
final backendUrl = file.appProperties?['backend-url'];
```

### 4. Multi-Tenant Applications

```dart
// Tag files with user/tenant ID
final file = drive.File()
  ..name = 'Customer Orders'
  ..appProperties = {
    'app': 'my-purchase-app',
    'tenant-id': 'customer-123',
    'user-email': 'user@company.com',
    'department': 'sales',
  };

// Find files for specific tenant
final tenantFiles = await driveApi.files.list(
  q: "appProperties has { key='app' and value='my-purchase-app' } "
     "and appProperties has { key='tenant-id' and value='customer-123' }",
);
```

### 5. Workflow and Status Tracking

```dart
// Track file processing status
await updateAppProperties(driveApi, fileId, {
  'status': 'processing',
  'started-at': DateTime.now().toIso8601String(),
});

// After processing
await updateAppProperties(driveApi, fileId, {
  'status': 'completed',
  'completed-at': DateTime.now().toIso8601String(),
  'records-processed': '1234',
});

// Find files by status
final pendingFiles = await driveApi.files.list(
  q: "appProperties has { key='app' and value='my-purchase-app' } "
     "and appProperties has { key='status' and value='pending' }",
);
```

## Query Syntax Reference

### Basic Syntax

```dart
// Single property match
"appProperties has { key='propertyName' and value='propertyValue' }"

// Multiple properties (AND)
"appProperties has { key='app' and value='my-app' } "
"and appProperties has { key='type' and value='data' }"

// Combined with other queries
"appProperties has { key='app' and value='my-app' } "
"and mimeType='application/vnd.google-apps.spreadsheet' "
"and trashed=false "
"and 'me' in owners"
```

### Common Query Patterns

```dart
// Find by app
final q1 = "appProperties has { key='app' and value='my-purchase-app' }";

// Find specific type
final q2 = "appProperties has { key='app' and value='my-purchase-app' } "
           "and appProperties has { key='type' and value='purchase-tracking' }";

// Find non-deployed sheets
final q3 = "appProperties has { key='app' and value='my-purchase-app' } "
           "and appProperties has { key='backend-deployed' and value='false' }";

// Find recent files (created in last 7 days)
final q4 = "appProperties has { key='app' and value='my-purchase-app' } "
           "and createdTime > '${DateTime.now().subtract(Duration(days: 7)).toIso8601String()}'";

// Find files shared with specific user
final q5 = "appProperties has { key='app' and value='my-purchase-app' } "
           "and 'user@example.com' in readers";
```

## Best Practices

### 1. Consistent Naming Convention

```dart
// Use consistent key names across your app
class AppPropertyKeys {
  static const app = 'app';
  static const appVersion = 'app-version';
  static const dataSchemaVersion = 'data-schema-version';
  static const sheetType = 'sheet-type';
  static const backendDeployed = 'backend-deployed';
  static const createdBy = 'created-by';
  static const lastModifiedBy = 'last-modified-by';
}

// Use the constants
final properties = {
  AppPropertyKeys.app: 'my-purchase-app',
  AppPropertyKeys.dataSchemaVersion: '2.0',
  AppPropertyKeys.backendDeployed: 'false',
};
```

### 2. Version Your Schema

```dart
// Always include schema version for future migrations
final file = drive.File()
  ..appProperties = {
    'app': 'my-purchase-app',
    'data-schema-version': '2.1',  // Critical for migrations
    'app-version': '1.5.0',         // App version that created it
  };
```

### 3. Use Typed Values Consistently

```dart
// For booleans, use 'true'/'false' strings consistently
properties['enabled'] = value ? 'true' : 'false';

// For numbers, convert to string
properties['count'] = count.toString();

// For dates, use ISO 8601
properties['created-at'] = DateTime.now().toIso8601String();

// For enums/states, use consistent string values
properties['status'] = status.name; // 'pending', 'processing', 'completed'
```

### 4. Create Helper Functions

```dart
class DriveAppProperties {
  static const appName = 'my-purchase-app';
  
  // Create standard properties
  static Map<String, String> createStandardProperties({
    required String type,
    required String schemaVersion,
    Map<String, String>? additional,
  }) {
    return {
      'app': appName,
      'type': type,
      'data-schema-version': schemaVersion,
      'created-at': DateTime.now().toIso8601String(),
      'created-by': 'api',
      ...?additional,
    };
  }
  
  // Build search query
  static String buildQuery({
    String? type,
    String? schemaVersion,
    bool? includeSheets = true,
    bool? includeTrashed = false,
  }) {
    final parts = <String>[
      "appProperties has { key='app' and value='$appName' }",
    ];
    
    if (type != null) {
      parts.add("appProperties has { key='type' and value='$type' }");
    }
    
    if (schemaVersion != null) {
      parts.add("appProperties has { key='data-schema-version' and value='$schemaVersion' }");
    }
    
    if (includeSheets == true) {
      parts.add("mimeType='application/vnd.google-apps.spreadsheet'");
    }
    
    if (includeTrashed == false) {
      parts.add("trashed=false");
    }
    
    return parts.join(' and ');
  }
}

// Usage
final file = drive.File()
  ..name = 'Purchase Sheet'
  ..mimeType = 'application/vnd.google-apps.spreadsheet'
  ..appProperties = DriveAppProperties.createStandardProperties(
    type: 'purchase-tracking',
    schemaVersion: '2.1',
    additional: {'user-id': '12345'},
  );

final query = DriveAppProperties.buildQuery(
  type: 'purchase-tracking',
  schemaVersion: '2.1',
);
```

### 5. Error Handling

```dart
Future<Map<String, String>?> getAppProperties(
  drive.DriveApi driveApi,
  String fileId,
) async {
  try {
    final file = await driveApi.files.get(
      fileId,
      $fields: 'appProperties',
    ) as drive.File;
    
    return file.appProperties;
  } on drive.DetailedApiRequestError catch (e) {
    if (e.status == 404) {
      print('File not found: $fileId');
      return null;
    }
    rethrow;
  } catch (e) {
    print('Error getting app properties: $e');
    return null;
  }
}
```

## Limitations and Considerations

### Property Limits
- **Maximum properties per file**: 124 custom properties (app + public combined)
- **Key length**: Maximum 124 characters
- **Value length**: Maximum 124 characters
- **Total size**: All properties combined cannot exceed 16 KB

### Performance
- Searching by app properties is efficient
- Multiple property queries are ANDed together
- No OR operator for property values (requires multiple queries)
- Consider caching frequently accessed properties

### Data Types
- **Only strings**: All values must be strings
- **No nested objects**: Flat key-value pairs only
- **Type conversion**: Must convert booleans, numbers, dates to strings

### Visibility
- **App properties**: Only visible to your app
- **Public properties**: Visible to all apps with file access
- **User visibility**: Properties are NOT visible in Google Drive UI

## Comparison: App Properties vs Alternatives

| Feature | App Properties | Description Field | Filename Pattern |
|---------|---------------|-------------------|------------------|
| Structured data | ✅ Key-value pairs | ❌ Plain text | ❌ Text pattern |
| Multiple values | ✅ Multiple keys | ⚠️ Comma-separated | ❌ Limited |
| Searchable | ✅ Efficient queries | ✅ Contains search | ✅ Name search |
| User editable | ❌ No | ✅ Yes | ✅ Yes |
| Private to app | ✅ Yes | ❌ No | ❌ No |
| Reliable | ✅ Immune to renames | ⚠️ Can be edited | ❌ User can rename |
| Best for | App metadata | User notes | User-facing files |

## Complete Example: Purchase App Integration

```dart
import 'package:googleapis/drive/v3.dart' as drive;

class PurchaseAppDriveManager {
  static const appName = 'my-purchase-app';
  static const currentSchemaVersion = '2.1';
  
  final drive.DriveApi driveApi;
  
  PurchaseAppDriveManager(this.driveApi);
  
  // Create new purchase tracking sheet
  Future<String> createPurchaseSheet(String name) async {
    final file = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.spreadsheet'
      ..description = 'Purchase tracking sheet created by Purchase App'
      ..appProperties = {
        'app': appName,
        'type': 'purchase-tracking',
        'data-schema-version': currentSchemaVersion,
        'created-at': DateTime.now().toIso8601String(),
        'backend-deployed': 'false',
        'auto-sync-enabled': 'false',
      };
    
    final created = await driveApi.files.create(
      file,
      $fields: 'id, name, webViewLink',
    );
    
    return created.id!;
  }
  
  // Find all purchase sheets
  Future<List<drive.File>> findAllPurchaseSheets() async {
    final query = "appProperties has { key='app' and value='$appName' } "
                  "and appProperties has { key='type' and value='purchase-tracking' } "
                  "and trashed=false";
    
    final result = await driveApi.files.list(
      q: query,
      $fields: 'files(id, name, webViewLink, appProperties, modifiedTime)',
      orderBy: 'modifiedTime desc',
    );
    
    return result.files ?? [];
  }
  
  // Mark sheet as deployed
  Future<void> markAsDeployed(String fileId, String backendUrl) async {
    final file = await driveApi.files.get(
      fileId,
      $fields: 'appProperties',
    ) as drive.File;
    
    final updatedProperties = {
      ...?file.appProperties,
      'backend-deployed': 'true',
      'backend-url': backendUrl,
      'deployed-at': DateTime.now().toIso8601String(),
    };
    
    await driveApi.files.update(
      drive.File()..appProperties = updatedProperties,
      fileId,
    );
  }
  
  // Find sheets needing migration
  Future<List<drive.File>> findSheetsNeedingMigration() async {
    final query = "appProperties has { key='app' and value='$appName' } "
                  "and not appProperties has { key='data-schema-version' and value='$currentSchemaVersion' }";
    
    final result = await driveApi.files.list(
      q: query,
      $fields: 'files(id, name, appProperties)',
    );
    
    return result.files ?? [];
  }
  
  // Check if file belongs to this app
  Future<bool> isOurSheet(String fileId) async {
    try {
      final file = await driveApi.files.get(
        fileId,
        $fields: 'appProperties',
      ) as drive.File;
      
      return file.appProperties?['app'] == appName &&
             file.appProperties?['type'] == 'purchase-tracking';
    } catch (e) {
      return false;
    }
  }
}

// Usage
final manager = PurchaseAppDriveManager(driveApi);

// Create sheet
final sheetId = await manager.createPurchaseSheet('2026 Purchases');

// Deploy backend
await deployBackend(sheetId);
await manager.markAsDeployed(sheetId, 'https://script.google.com/...');

// Find all sheets
final allSheets = await manager.findAllPurchaseSheets();
print('Found ${allSheets.length} purchase sheets');

// Check for migrations
final outdatedSheets = await manager.findSheetsNeedingMigration();
if (outdatedSheets.isNotEmpty) {
  print('${outdatedSheets.length} sheets need migration');
}
```

## Related Documentation

- [Google Drive API - Files: create](https://developers.google.com/drive/api/v3/reference/files/create)
- [Google Drive API - Files: update](https://developers.google.com/drive/api/v3/reference/files/update)
- [Google Drive API - Search for files](https://developers.google.com/drive/api/guides/search-files)
- [Google Drive API - Custom file properties](https://developers.google.com/drive/api/guides/properties)
- [Drive API Query Language](https://developers.google.com/drive/api/guides/search-files#query_string_examples)

## Summary

**Use App Properties when you need to:**
- Tag files created by your app
- Store app-specific metadata
- Search for files by criteria beyond name/type
- Track versions for migrations
- Store configuration without modifying file content
- Reliably identify your app's files regardless of user actions

**Remember:**
- Properties are private to your app (app properties) or public (properties)
- All values must be strings (convert types as needed)
- Limited to 124 properties and 16 KB total
- Efficient for searching and filtering
- Invisible to users in Drive UI
