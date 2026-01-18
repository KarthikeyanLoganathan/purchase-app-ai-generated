import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purchase_app/base/model_definition.dart';
import 'package:purchase_app/utils/change_log_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import '../base/data_definition.dart';
import '../utils/settings_manager.dart';

/// Unified service for importing and exporting database tables to/from CSV files
class ExportImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================================
  // EXPORT FUNCTIONALITY
  // ============================================================================

  /// Export all database tables to CSV files and create a timestamped zip file
  /// Returns the path to the created zip file
  Future<String> exportAllTablesToCsvZip() async {
    debugPrint('===== CSV EXPORT STARTING =====');

    // Generate timestamp for the zip file name
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final zipFileName = '$timestamp-purchase-app-data.zip';

    // Create archive
    final archive = Archive();

    // Export each table to CSV and add to archive
    for (final tableName in DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
    ])) {
      try {
        debugPrint('Exporting table: $tableName');
        final csvContent = await _exportTableToCsv(tableName);

        if (csvContent.isNotEmpty) {
          final csvFileName = '$tableName.csv';
          final csvBytes = utf8.encode(csvContent);

          archive.addFile(
            ArchiveFile(csvFileName, csvBytes.length, csvBytes),
          );
          debugPrint(
              'Added $csvFileName to archive (${csvBytes.length} bytes)');
        } else {
          debugPrint('Table $tableName is empty, skipping');
        }
      } catch (e) {
        debugPrint('Error exporting table $tableName: $e');
        // Continue with other tables even if one fails
      }
    }

    // Encode the archive as a zip file
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode zip archive');
    }

    // Get temporary directory to save the zip file
    final tempDir = await getTemporaryDirectory();
    final zipFilePath = '${tempDir.path}/$zipFileName';

    // Write the zip file
    final zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(zipData);

    debugPrint('===== CSV EXPORT COMPLETED =====');
    debugPrint('Zip file created at: $zipFilePath');
    debugPrint('File size: ${zipFile.lengthSync()} bytes');

    return zipFilePath;
  }

  /// Export a single table to CSV format
  Future<String> _exportTableToCsv(String tableName) async {
    final db = await _dbHelper.database;
    final tableDefinition = DataDefinition.getModelDefinition(tableName);

    // Query all data from the table
    final data = await db.query(tableName);

    if (data.isEmpty) {
      return '';
    }

    // Get column names from the first row
    final columns = data.first.keys.toList();

    // Create CSV data
    final csvData = <List<dynamic>>[];

    // Add header row
    csvData.add(columns);

    // Add data rows
    for (final row in data) {
      final modelInstance = tableDefinition!.fromDbMap(row);
      final typedRecord = tableDefinition.toCsvMap(modelInstance);
      final rowData = columns.map((column) {
        final value = typedRecord[column];
        // Convert null to empty string
        return value ?? '';
      }).toList();
      csvData.add(rowData);
    }

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    debugPrint('Exported ${data.length} rows from $tableName');
    return csvString;
  }

  /// Share the exported zip file using the system share dialog
  Future<void> shareExportedCsvZip(String zipFilePath) async {
    final zipFile = File(zipFilePath);

    if (!await zipFile.exists()) {
      throw Exception('Zip file not found: $zipFilePath');
    }

    final xFile = XFile(
      zipFilePath,
      name: zipFilePath.split('/').last,
      mimeType: 'application/zip',
    );

    await Share.shareXFiles(
      [xFile],
      subject: 'Purchase App Data Export',
      text: 'Exported database from Purchase App',
    );

    debugPrint('Shared zip file: $zipFilePath');
  }

  /// Save the exported zip file to Downloads directory
  /// Returns the path where the file was saved
  Future<String> saveCsvZipToDownloads(String zipFilePath) async {
    final zipFile = File(zipFilePath);

    if (!await zipFile.exists()) {
      throw Exception('Zip file not found: $zipFilePath');
    }

    Directory? targetDir;

    if (Platform.isAndroid) {
      // For Android, use the app's external storage directory
      // This doesn't require special permissions and is accessible to users
      targetDir = await getExternalStorageDirectory();

      if (targetDir == null) {
        throw Exception('Could not access external storage directory');
      }

      // Navigate up to the root of external storage and into Downloads
      // From: /storage/emulated/0/Android/data/com.package/files
      // To: /storage/emulated/0/Download
      final pathSegments = targetDir.path.split('/');
      final storageIndex = pathSegments.indexOf('Android');

      if (storageIndex > 0) {
        // Build path to public Downloads directory
        final publicPath = pathSegments.sublist(0, storageIndex).join('/');

        // Try both Download and Downloads
        targetDir = Directory('$publicPath/Download');
        if (!await targetDir.exists()) {
          targetDir = Directory('$publicPath/Downloads');
        }

        // If public Downloads doesn't exist or isn't accessible, use app directory
        if (!await targetDir.exists()) {
          debugPrint('Public Downloads not accessible, using app directory');
          targetDir = await getExternalStorageDirectory();
          if (targetDir != null) {
            targetDir = Directory('${targetDir.path}/Exports');
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }
          }
        }
      } else {
        // Fallback to app's external directory with Exports subfolder
        targetDir = Directory('${targetDir.path}/Exports');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
    } else {
      // For iOS, use the app's documents directory
      targetDir = await getApplicationDocumentsDirectory();
    }

    if (targetDir == null) {
      throw Exception('Could not access storage directory');
    }

    // Copy file to target directory
    final fileName = zipFilePath.split('/').last;
    final savedFilePath = '${targetDir.path}/$fileName';

    try {
      await zipFile.copy(savedFilePath);
      debugPrint('Saved zip file to: $savedFilePath');
      return savedFilePath;
    } catch (e) {
      // If copy fails (e.g., permission denied), try app directory as last resort
      debugPrint('Failed to save to $savedFilePath: $e');
      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        final fallbackDir = Directory('${appDir.path}/Exports');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        final fallbackPath = '${fallbackDir.path}/$fileName';
        await zipFile.copy(fallbackPath);
        debugPrint('Saved to fallback location: $fallbackPath');
        return fallbackPath;
      }
      rethrow;
    }
  }

  /// Get a user-friendly export summary
  Future<Map<String, dynamic>> getCsvExportSummary() async {
    final db = await _dbHelper.database;
    final summary = <String, int>{};
    int totalRows = 0;

    for (final tableName in DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
    ])) {
      final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
          ) ??
          0;

      if (count > 0) {
        summary[tableName] = count;
        totalRows += count;
      }
    }

    return {
      'tables': summary,
      'totalTables': summary.length,
      'totalRows': totalRows,
    };
  }

  // ============================================================================
  // IMPORT FUNCTIONALITY
  // ============================================================================

  /// Get list of CSV files from AssetManifest
  /// Uses Flutter's official AssetManifest API (Flutter 3.x+)
  Future<List<String>> getCsvFilesFromAssetBundle() async {
    try {
      // Use Flutter's official AssetManifest API
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets().toList();

      // Filter for .csv files in the sample-data directory
      final csvFiles = allAssets
          .where((String key) =>
              key.startsWith('sample-data/') && key.endsWith('.csv'))
          .toList();

      csvFiles.sort();
      return csvFiles;
    } catch (e) {
      // Return hardcoded list as fallback
      return [
        'sample-data/${TableNames.currencies}.csv',
        'sample-data/${TableNames.manufacturerMaterials}.csv',
        'sample-data/${TableNames.manufacturers}.csv',
        'sample-data/${TableNames.materials}.csv',
        'sample-data/${TableNames.projects}.csv',
        'sample-data/${TableNames.unitOfMeasures}.csv',
        'sample-data/${TableNames.vendorPriceLists}.csv',
        'sample-data/${TableNames.vendors}.csv',
      ];
    }
  }

  Future<Map<String, dynamic>> importFromSampleDataAssets() async {
    final results = <String, int>{};
    final errors = <String>[];
    int totalImported = 0;
    int totalErrors = 0;

    try {
      // Clear all existing data before importing sample data
      await _dbHelper.clearAllData();

      // Dynamically discover all CSV files
      final csvFiles = await getCsvFilesFromAssetBundle();

      // Import each CSV file
      for (String csvFileName in csvFiles) {
        // Extract table name from file name: sample-data/currencies.csv -> currencies
        final tableName = csvFileName
            .replaceFirst('sample-data/', '')
            .replaceFirst('.csv', '');

        final result = await importSingleCsvFromAsset(tableName, csvFileName);
        results[tableName] = result['imported'] as int;
        totalImported += result['imported'] as int;
        totalErrors += result['errors'] as int;

        if (result['error'] != null) {
          errors.add('$tableName: ${result['error']}');
        }
      }

      await ChangeLogUtils(_dbHelper).initializeChangeLogFromDataTables();

      return {
        'success': totalImported > 0 || errors.isEmpty,
        'totalImported': totalImported,
        'totalErrors': totalErrors,
        'details': results,
        'errorDetails': errors.isEmpty ? null : errors.join('\n'),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'totalImported': totalImported,
        'totalErrors': totalErrors,
        'details': results,
        'errorDetails': e.toString(),
      };
    }
  }

  /// Import a single CSV file from assets into the specified table
  Future<Map<String, dynamic>> importSingleCsvFromAsset(
      String tableName, String csvFileName) async {
    try {
      final String csvData = await rootBundle.loadString(csvFileName);
      return await _importCsvData(tableName, csvData);
    } catch (e) {
      return {
        'imported': 0,
        'errors': 1,
        'error': 'Failed to load asset: ${e.toString().split('\n').first}',
        'errorMessages': [
          'Failed to load asset: ${e.toString().split('\n').first}'
        ],
      };
    }
  }

  /// Import CSV data into the specified table
  /// Uses the model's fromMap factory for proper type conversion
  Future<Map<String, dynamic>> _importCsvData(
      String tableName, String csvData) async {
    int imported = 0;
    int errors = 0;
    String? lastError;
    final List<String> errorMessages = [];
    final tableDefinition = DataDefinition.getModelDefinition(tableName);

    try {
      // Parse CSV with proper line ending handling
      final List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter(eol: '\n').convert(csvData);

      if (rowsAsListOfValues.isEmpty) {
        return {
          'imported': 0,
          'errors': 0,
          'error': 'Empty CSV file',
          'errorMessages': ['CSV file is empty']
        };
      }

      // Read header row and create column map
      final headers = rowsAsListOfValues[0]
          .map((h) => h.toString().trim().toLowerCase())
          .toList();
      final Map<String, int> columnMap = {};
      for (int i = 0; i < headers.length; i++) {
        columnMap[headers[i]] = i;
      }

      // Collect records for batch insert
      final List<Map<String, dynamic>> recordsToInsert = [];
      final List<Map<String, dynamic>> recordsToUpdate = [];

      final db = await _dbHelper.database;
      // Process each data row
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        try {
          final row = rowsAsListOfValues[i];

          // Skip empty rows
          if (row.isEmpty ||
              row.every((cell) => cell.toString().trim().isEmpty)) {
            continue;
          }

          // Build raw record map from row data (string values from CSV)
          final Map<String, dynamic> rawRecord = {};

          for (String header in headers) {
            final colIndex = columnMap[header]!;
            if (colIndex < row.length) {
              final cellValue = row[colIndex];
              final stringValue = cellValue.toString().trim();
              rawRecord[header] = stringValue.isEmpty ? null : stringValue;
            }
          }

          // Ensure updated_at is set if not present
          if (!rawRecord.containsKey('updated_at') ||
              rawRecord['updated_at'] == null) {
            rawRecord['updated_at'] = DateTime.now().toUtc().toIso8601String();
          }

          // Convert to properly typed record using model's fromMap
          Map<String, dynamic>? typedRecord;
          try {
            // Use the model's fromMap to get proper types, then convert back to map
            final modelInstance = tableDefinition!.fromCsvMap(rawRecord);
            typedRecord = tableDefinition.toDbMap(modelInstance);
          } catch (e) {
            // If model factory fails, fall back to heuristic parsing
            final errorMsg = 'Row ${i + 1}: ${e.toString().split('\n').first}';
            errorMessages.add(errorMsg);
          }

          if (typedRecord != null) {
            // Check if record already exists (based on uuid or name)
            final primaryKey = tableDefinition!.primaryKeyField!.tableFieldName;
            if (typedRecord.containsKey(primaryKey)) {
              final existing = await db.query(
                tableName,
                where: '$primaryKey = ?',
                whereArgs: [typedRecord[primaryKey]],
              );

              if (existing.isNotEmpty) {
                recordsToUpdate.add(typedRecord);
              } else {
                recordsToInsert.add(typedRecord);
              }
            } else {
              recordsToInsert.add(typedRecord);
            }
          }
        } catch (e) {
          errors++;
          final errorMsg = 'Row ${i + 1}: ${e.toString().split('\n').first}';
          lastError = errorMsg;
          errorMessages.add(errorMsg);
        }
      }

      // Batch insert new records
      if (recordsToInsert.isNotEmpty) {
        await db.transaction((txn) async {
          for (final record in recordsToInsert) {
            await txn.insert(tableName, record);
            imported++;
          }
        });
      }

      // Batch update existing records
      if (recordsToUpdate.isNotEmpty) {
        await db.transaction((txn) async {
          for (final record in recordsToUpdate) {
            final primaryKey = record.containsKey('uuid') ? 'uuid' : 'name';
            await txn.update(
              tableName,
              record,
              where: '$primaryKey = ?',
              whereArgs: [record[primaryKey]],
            );
            imported++;
          }
        });
      }

      return {
        'imported': imported,
        'errors': errors,
        'error': lastError,
        'errorMessages': errorMessages,
      };
    } catch (e) {
      return {
        'imported': 0,
        'errors': 1,
        'error': e.toString().split('\n').first,
        'errorMessages': [e.toString().split('\n').first],
      };
    }
  }

  /// Import CSV files from a zip archive
  /// Returns a map with import statistics
  Future<Map<String, dynamic>> importFromZipFile(String zipFilePath) async {
    final results = <String, int>{};
    int totalRecords = 0;
    int totalErrors = 0;
    final errors = <String>[];

    try {
      // Read zip file
      final bytes = await File(zipFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // First, validate that the zip contains CSV files
      final csvFiles = archive.files
          .where(
              (file) => file.isFile && file.name.toLowerCase().endsWith('.csv'))
          .toList();

      if (csvFiles.isEmpty) {
        throw Exception('No CSV files found in the zip archive');
      }

      // Clear all existing data before importing from zip
      await _dbHelper.clearAllData();

      // Process each CSV file directly from memory
      for (final file in csvFiles) {
        final fileName = file.name.split('/').last;
        final tableName = fileName.replaceAll('.csv', '');

        try {
          // Convert file content directly to string (no temp files)
          final data = file.content as List<int>;
          final csvContent = String.fromCharCodes(data);

          final result = await _importCsvData(tableName, csvContent);

          final hasErrors = (result['errors'] as int?) ?? 0;
          final recordCount = (result['imported'] as num?)?.toInt() ?? 0;

          results[tableName] = recordCount;
          totalRecords += recordCount;

          if (hasErrors > 0) {
            totalErrors += hasErrors;
            final errorMsgs = result['errorMessages'] as List<String>? ?? [];
            if (errorMsgs.isNotEmpty) {
              errors.addAll(errorMsgs.take(3).map((msg) => '$tableName: $msg'));
              if (errorMsgs.length > 3) {
                errors.add(
                    '$tableName: ... +${errorMsgs.length - 3} more errors');
              }
            } else {
              final error = result['error'] ?? 'Unknown error';
              errors.add('$tableName: $error');
            }
          }
        } catch (e) {
          totalErrors++;
          errors.add('$tableName: ${e.toString().split('\n').first}');
        }
      }

      await ChangeLogUtils(_dbHelper).initializeChangeLogFromDataTables();

      await SettingsManager.instance.loadDefaults();

      return {
        'success': totalErrors == 0,
        'totalRecords': totalRecords,
        'totalErrors': totalErrors,
        'results': results,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'totalRecords': 0,
        'totalErrors': 1,
        'results': {},
        'errors': ['Failed to read zip file: $e'],
      };
    }
  }

  // ============================================================================
  // GOOGLE SHEETS INTEGRATION
  // ============================================================================

  /// Upload all local data to Google Sheets
  ///
  /// Parameters:
  /// - [sheetId]: The Google Spreadsheet ID
  /// - [client]: Authenticated HTTP client with Google Sheets API access
  /// - [onProgress]: Optional callback for progress updates
  ///
  /// Returns a map with:
  /// - 'tablesProcessed': Number of tables successfully processed
  /// - 'recordsUploaded': Total number of records uploaded
  Future<Map<String, int>> uploadDataToGoogleSheets({
    required String sheetId,
    required http.Client client,
    Function(String message)? onProgress,
  }) async {
    final db = await _dbHelper.database;
    await ChangeLogUtils(_dbHelper).initializeChangeLogFromDataTables();
    final sheetsApi = sheets.SheetsApi(client);

    int totalRecordsUploaded = 0;
    int totalTablesProcessed = 0;

    // Process each table
    for (final tableName in DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
      ModelTypes.log
    ])) {
      final tableDefinition = DataDefinition.getModelDefinition(tableName);
      try {
        onProgress?.call('Processing table: $tableName...');
        debugPrint('[Upload] Processing table: $tableName');

        // Get table column names from SQLite
        final tableColumnNames = await _dbHelper.getTableColumnNames(tableName);
        debugPrint('[Upload] Table columns: $tableColumnNames');

        // Get Google Sheet worksheet by name
        final spreadsheet = await sheetsApi.spreadsheets.get(sheetId);
        final sheet = spreadsheet.sheets?.firstWhere(
          (s) => s.properties?.title == tableName,
          orElse: () => throw Exception('Sheet $tableName not found'),
        );

        if (sheet == null) {
          debugPrint('[Upload] Sheet $tableName not found, skipping');
          continue;
        }

        // Get the actual column count from sheet properties
        final sheetProperties = sheet.properties!;
        final maxCols = sheetProperties.gridProperties?.columnCount ?? 26;
        final lastColLetter =
            _columnIndexToLetterInGoogleSheet(maxCols - 1); // 0-based index

        // Get sheet column names from first row
        final headerResponse = await sheetsApi.spreadsheets.values.get(
          sheetId,
          '$tableName!A1:$lastColLetter\$1',
        );

        final sheetColumnNames = headerResponse.values?.isNotEmpty == true
            ? headerResponse.values!.first.map((e) => e.toString()).toList()
            : <String>[];

        debugPrint(
            '[Upload] Sheet columns ($maxCols total): $sheetColumnNames');

        if (sheetColumnNames.isEmpty) {
          debugPrint('[Upload] Sheet $tableName has no headers, skipping');
          continue;
        }

        // Clean up existing data rows (similar to cleanup.js cleanupSheet logic)
        final sheetIdNum = sheet.properties!.sheetId!;

        // Get the current number of rows in the sheet
        final maxRows = sheetProperties.gridProperties?.rowCount ?? 1;

        debugPrint('[Upload] Sheet $tableName has $maxRows total rows');

        if (maxRows > 1) {
          final numRowsToClear = maxRows - 1; // Exclude header row

          // Step 1: Clear content of all data rows (keep rows but remove content)
          await sheetsApi.spreadsheets.values.clear(
            sheets.ClearValuesRequest(),
            sheetId,
            '$tableName!A2:$lastColLetter$maxRows', // Clear exact columns from row 2 onwards
          );
          debugPrint(
              '[Upload] Cleared content of $numRowsToClear rows from $tableName');

          // Step 2: Delete all rows after row 2 (keep header + one empty row)
          if (maxRows > 2) {
            final deleteRequest = sheets.Request(
              deleteDimension: sheets.DeleteDimensionRequest(
                range: sheets.DimensionRange(
                  sheetId: sheetIdNum,
                  dimension: 'ROWS',
                  startIndex: 2, // Row 3 (0-indexed)
                  endIndex: maxRows, // Up to last row
                ),
              ),
            );

            await sheetsApi.spreadsheets.batchUpdate(
              sheets.BatchUpdateSpreadsheetRequest(requests: [deleteRequest]),
              sheetId,
            );
            debugPrint(
                '[Upload] Deleted ${maxRows - 2} extra rows from $tableName');
          }
        } else {
          debugPrint('[Upload] $tableName is already empty');
        }

        // Query all records from SQLite in batches
        const batchSize = 200;
        int offset = 0;
        int recordsProcessed = 0;

        while (true) {
          final records = await db.query(
            tableName,
            limit: batchSize,
            offset: offset,
          );

          if (records.isEmpty) break;

          debugPrint(
              '[Upload] Processing batch: $offset to ${offset + records.length}');

          // Prepare Excel rows
          final List<List<dynamic>> excelRows = [];

          for (final row in records) {
            final excelRow = <dynamic>[];
            final typedRecord =
                tableDefinition!.toSheetMap(tableDefinition.fromDbMap(row));

            // Map values from database column layout to Excel column layout
            for (final sheetCol in sheetColumnNames) {
              // Find matching database column (case-insensitive)
              final String? dbCol = tableColumnNames
                  .where((col) => col.toLowerCase() == sheetCol.toLowerCase())
                  .firstOrNull;
              if (dbCol == null) continue;
              dynamic value = typedRecord[dbCol];
              excelRow.add(value ?? '');
            }
            excelRows.add(excelRow);
          }

          // Append rows to sheet
          if (excelRows.isNotEmpty) {
            final valueRange = sheets.ValueRange.fromJson({
              'values': excelRows,
            });

            await sheetsApi.spreadsheets.values.append(
              valueRange,
              sheetId,
              '$tableName!A2', // Start from row 2
              valueInputOption: 'RAW',
            );

            recordsProcessed += excelRows.length;
            totalRecordsUploaded += excelRows.length;
            debugPrint(
                '[Upload] Uploaded ${excelRows.length} records to $tableName');
          }

          offset += batchSize;

          // Check if we have more records
          if (records.length < batchSize) break;
        }

        debugPrint('[Upload] Completed $tableName: $recordsProcessed records');
        totalTablesProcessed++;
      } catch (e) {
        debugPrint(
            '[Upload] Error processing table $tableName: ${jsonEncode(e)}');
        // Continue with next table
      }
    }

    // Get max updated_at from change_log before clearing
    final changeLogUtils = ChangeLogUtils(_dbHelper);
    final lastSyncTimestamp = await changeLogUtils.getLastSyncTimestampByLog();
    await SettingsManager.instance.setLastSyncTimestamp(lastSyncTimestamp);
    debugPrint('[Upload] Updated last sync timestamp: $lastSyncTimestamp');

    // Clear change logs
    debugPrint('[Upload] Clearing change logs...');
    await db.delete(TableNames.changeLog);
    await db.delete(TableNames.condensedChangeLog);
    debugPrint('[Upload] Change logs cleared');

    return {
      'tablesProcessed': totalTablesProcessed,
      'recordsUploaded': totalRecordsUploaded,
    };
  }

  /// Import all data from Google Sheets to local database
  ///
  /// Parameters:
  /// - [sheetId]: The Google Spreadsheet ID
  /// - [client]: Authenticated HTTP client with Google Sheets API access
  /// - [onProgress]: Optional callback for progress updates
  ///
  /// Returns a map with:
  /// - 'tablesProcessed': Number of tables successfully processed
  /// - 'recordsImported': Total number of records imported
  Future<Map<String, int>> importDataFromGoogleSheet({
    required String sheetId,
    required http.Client client,
    Function(String message)? onProgress,
  }) async {
    final db = await _dbHelper.database;
    final sheetsApi = sheets.SheetsApi(client);

    int totalRecordsImported = 0;
    int totalTablesProcessed = 0;

    // Process each table
    for (final tableName in DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData
    ])) {
      final tableDefinition = DataDefinition.getModelDefinition(tableName);
      try {
        onProgress?.call('Importing table: $tableName...');
        debugPrint('[Import] Processing table: $tableName');

        // Get table column names from SQLite
        final tableColumnNames = await _dbHelper.getTableColumnNames(tableName);
        debugPrint('[Import] Table columns: $tableColumnNames');

        // Get Google Sheet worksheet by name
        final spreadsheet = await sheetsApi.spreadsheets.get(sheetId);
        final sheet = spreadsheet.sheets?.firstWhere(
          (s) => s.properties?.title == tableName,
          orElse: () => throw Exception('Sheet $tableName not found'),
        );

        if (sheet == null) {
          debugPrint('[Import] Sheet $tableName not found, skipping');
          continue;
        }

        // Get the actual column count from sheet properties
        final sheetProperties = sheet.properties!;
        final maxCols = sheetProperties.gridProperties?.columnCount ?? 26;
        final lastColLetter =
            _columnIndexToLetterInGoogleSheet(maxCols - 1); // 0-based index

        // Get sheet column names from first row
        final headerResponse = await sheetsApi.spreadsheets.values.get(
          sheetId,
          '$tableName!A1:$lastColLetter\$1',
        );

        final sheetColumnNames = headerResponse.values?.isNotEmpty == true
            ? headerResponse.values!.first.map((e) => e.toString()).toList()
            : <String>[];

        debugPrint(
            '[Import] Sheet columns ($maxCols total): $sheetColumnNames');

        if (sheetColumnNames.isEmpty) {
          debugPrint('[Import] Sheet $tableName has no headers, skipping');
          continue;
        }

        // Delete all records from SQLite table
        debugPrint('[Import] Clearing table $tableName...');
        await db.delete(tableName);
        debugPrint('[Import] Table $tableName cleared');

        // Read data from sheet in batches of 200 rows
        const batchSize = 200;
        int rowOffset = 2; // Start from row 2 (after header)
        int recordsImported = 0;

        while (true) {
          final startRow = rowOffset;
          final endRow = rowOffset + batchSize - 1;

          debugPrint(
              '[Import] Reading rows $startRow to $endRow from $tableName...');

          // Read batch of rows
          final dataResponse = await sheetsApi.spreadsheets.values.get(
              sheetId, '$tableName!A$startRow:$lastColLetter$endRow',
              valueRenderOption: 'UNFORMATTED_VALUE');

          final sheetDataBatch = dataResponse.values ?? [];

          if (sheetDataBatch.isEmpty) {
            debugPrint('[Import] No more data in $tableName');
            break;
          }

          debugPrint(
              '[Import] Processing ${sheetDataBatch.length} rows from $tableName...');

          // Collect dbRows for batch insert
          final List<Map<String, dynamic>> dbRows = [];

          for (final sheetRec in sheetDataBatch) {
            try {
              // Skip empty rows
              if (sheetRec.isEmpty ||
                  sheetRec.every((cell) => cell.toString().trim().isEmpty)) {
                continue;
              }

              // Map values from sheet column layout to database column layout
              final Map<String, dynamic> rawRecord = {};

              for (int i = 0; i < sheetColumnNames.length; i++) {
                final sheetCol = sheetColumnNames[i];

                // Find matching database column (case-insensitive)
                final String? dbCol = tableColumnNames
                    .where((col) => col.toLowerCase() == sheetCol.toLowerCase())
                    .firstOrNull;

                // Skip columns that don't exist in the database schema
                if (dbCol == null) continue;

                // Get value from sheet row
                final cellValue = i < sheetRec.length ? sheetRec[i] : null;
                final stringValue = cellValue?.toString().trim() ?? '';
                dynamic value = stringValue.isEmpty ? null : stringValue;
                rawRecord[dbCol] = value;
              }

              // Ensure updated_at is set if not present
              if (!rawRecord.containsKey('updated_at') ||
                  rawRecord['updated_at'] == null) {
                rawRecord['updated_at'] =
                    DateTime.now().toUtc().toIso8601String();
              }

              // Convert to properly typed record using model's fromMap
              Map<String, dynamic>? typedRecord;
              try {
                // Use the model's fromMap to get proper types, then convert back to map
                final modelInstance = tableDefinition!.fromSheetMap(rawRecord);
                typedRecord = tableDefinition.toDbMap(modelInstance);
              } catch (e) {
                debugPrint(
                    '[Import] Model factory failed for row in $tableName: $e');
              }
              if (typedRecord != null) {
                dbRows.add(typedRecord);
              }
            } catch (e) {
              debugPrint('[Import] Error processing row in $tableName: $e');
              // Continue with next row
            }
          }

          // Batch insert into table
          if (dbRows.isNotEmpty) {
            await db.transaction((txn) async {
              for (final record in dbRows) {
                await txn.insert(tableName, record);
              }
            });

            recordsImported += dbRows.length;
            totalRecordsImported += dbRows.length;
            debugPrint(
                '[Import] Inserted ${dbRows.length} records into $tableName');
          }

          // Check if we have more rows
          if (sheetDataBatch.length < batchSize) {
            // Last batch (partial or complete)
            break;
          }

          rowOffset += batchSize;
        }

        debugPrint('[Import] Completed $tableName: $recordsImported records');
        totalTablesProcessed++;
      } catch (e) {
        debugPrint('[Import] Error processing table $tableName: $e');
        // Continue with next table
      }
    }

    // Initialize change log from imported data
    debugPrint('[Import] Initializing change log from imported data...');
    await ChangeLogUtils(_dbHelper).initializeChangeLogFromDataTables();
    debugPrint('[Import] Change log initialized');

    await SettingsManager.instance.loadDefaults();

    return {
      'tablesProcessed': totalTablesProcessed,
      'recordsImported': totalRecordsImported,
    };
  }

  /// Read statistics from the "statistics" sheet
  ///
  /// Parameters:
  /// - [sheetId]: The Google Spreadsheet ID
  /// - [client]: Authenticated HTTP client with Google Sheets API access
  ///
  /// Returns a map with:
  /// - Key: String from first column
  /// - Value: Number from second column
  Future<Map<String, int>> readDataStatisticsFromGoogleSheet({
    required String sheetId,
    required http.Client client,
  }) async {
    final sheetsApi = sheets.SheetsApi(client);
    final result = <String, int>{};

    try {
      debugPrint('[Statistics] Reading statistics sheet...');

      // Read columns A and B from row 2 onwards
      final response = await sheetsApi.spreadsheets.values.get(
        sheetId,
        'statistics!A2:B',
      );

      if (response.values == null || response.values!.isEmpty) {
        debugPrint('[Statistics] No data found in statistics sheet');
        return result;
      }

      // Process each row
      for (final row in response.values!) {
        // Skip if first column is empty
        if (row.isEmpty || row[0] == null || row[0].toString().trim().isEmpty) {
          continue;
        }

        final key = row[0].toString();

        // Get value from second column (default to 0 if missing or invalid)
        int value = 0;
        if (row.length > 1 && row[1] != null) {
          final valueStr = row[1].toString();
          value = int.tryParse(valueStr) ?? 0;
        }

        result[key] = value;
      }

      debugPrint('[Statistics] Read ${result.length} statistics entries');
      return result;
    } catch (e) {
      debugPrint('[Statistics] Error reading statistics: $e');
      throw Exception('Failed to read statistics: $e');
    }
  }

  /// Convert column index to Excel column letter (A, B, C, ..., Z, AA, AB, ...)
  String _columnIndexToLetterInGoogleSheet(int index) {
    String column = '';
    int temp = index;

    while (temp >= 0) {
      column = String.fromCharCode((temp % 26) + 65) + column;
      temp = (temp ~/ 26) - 1;
    }

    return column;
  }
}
