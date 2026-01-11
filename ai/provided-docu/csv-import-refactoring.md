# CSV Import Service Refactoring

## Overview

The CSV import service has been refactored from a hardcoded approach with individual import methods to a dynamic, generic solution that automatically discovers and imports all CSV files.

## Key Changes

### Before (1193 lines)
- 7 separate import methods (`_importUnitOfMeasures`, `_importCurrencies`, etc.)
- Duplicated parsing logic in each method
- Row-by-row insert/update operations
- Required code changes to add new CSV files

### After (274 lines - 77% reduction)
- Single generic `importSingleCsv()` method
- Automatic CSV file discovery using `AssetManifest.json`
- Batch insert/update operations (better performance)
- No code changes needed to add new CSV files

## New Architecture

```dart
getCsvFiles()
  ↓
importFromAssets()
  ↓
For each CSV file:
    ↓
  importSingleCsv(tableName, csvFileName)
    ↓
  - Parse CSV headers
  - Map rows to column names
  - Collect records (insert/update)
  - Batch insert in transaction
  - Batch update in transaction
  - Return statistics
```

## Key Features

### 1. Dynamic CSV Discovery

```dart
Future<List<String>> getCsvFiles() async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
  
  final files = manifestMap.keys
      .where((String key) => key.startsWith('sample-data/') && key.endsWith('.csv'))
      .toList();
  
  files.sort(); // Consistent import order
  return files;
}
```

### 2. Generic Import Function

```dart
Future<Map<String, dynamic>> importSingleCsv(
    String tableName, String csvFileName) async {
  // Load and parse CSV
  // Build column map from headers
  // Process each row
  // Batch operations
  // Return statistics
}
```

### 3. Smart Value Parsing

The `_parseValue()` method intelligently converts values based on column names:

- **Dates**: `updated_at`, `created_at`, `*_date` → ISO8601 strings
- **Booleans**: `is_*`, `active` → true/false (handles '1', 'true', 'yes')
- **Integers**: `*_id`, `size`, `quantity`, `decimal_places`
- **Decimals**: `price`, `rate`, `amount`, `tax`, `percent`
- **Strings**: Everything else

### 4. Batch Operations

Instead of individual inserts:
```dart
// Collect records
recordsToInsert.add(record);
recordsToUpdate.add(record);

// Batch insert in transaction
await db.transaction((txn) async {
  for (final record in recordsToInsert) {
    await txn.insert(tableName, record);
  }
});
```

## Benefits

1. **Reduced Code**: 77% reduction (1193 → 274 lines)
2. **Better Performance**: Batch operations instead of row-by-row
3. **Maintainability**: Single import logic, easy to modify
4. **Flexibility**: Add CSV files without code changes
5. **Consistency**: Same parsing rules for all CSVs
6. **Robust Error Handling**: Errors tracked per CSV file

## Usage

The API remains the same:

```dart
final csvImportService = CsvImportService();
final result = await csvImportService.importFromAssets();

print('Imported: ${result['totalImported']}');
print('Errors: ${result['totalErrors']}');
print('Details: ${result['details']}');
```

## Adding New CSV Files

Simply drop a new CSV file in the `sample-data/` folder and update `pubspec.yaml`:

```yaml
assets:
  - sample-data/
```

The import will automatically:
1. Discover the new file
2. Extract table name from filename
3. Parse headers and map columns
4. Import data with appropriate type conversions

No code changes required!

## Error Handling

- Per-row error tracking
- Continues on individual row errors
- Returns detailed error information
- Logs errors for debugging

## Performance Improvements

- **Batch Inserts**: Single transaction for all new records
- **Batch Updates**: Single transaction for all updates
- **Reduced DB Queries**: Check existence once per row
- **Optimized Parsing**: Reusable column map

## Future Enhancements

Potential improvements:
- Parallel CSV processing
- Configurable primary key detection
- Custom type converters
- CSV validation before import
- Progress callbacks
- Import from external files (not just assets)
