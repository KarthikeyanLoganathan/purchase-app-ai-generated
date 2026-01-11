import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purchase_app/utils/change_log_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import '../models/currency.dart';
import '../models/unit_of_measure.dart';
import '../models/manufacturer.dart';
import '../models/vendor.dart';
import '../models/material.dart';
import '../models/manufacturer_material.dart';
import '../models/vendor_price_list.dart';
import '../models/project.dart';
import '../models/basket.dart';
import '../models/basket_item.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../models/purchase_order_payment.dart';
import '../models/change_log.dart';
import '../models/condensed_change_log.dart';

/// Unified service for importing and exporting database tables to/from CSV files
class CsvExportImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================================
  // EXPORT FUNCTIONALITY
  // ============================================================================

  /// Export all database tables to CSV files and create a timestamped zip file
  /// Returns the path to the created zip file
  Future<String> exportAllTablesToZip() async {
    debugPrint('===== CSV EXPORT STARTING =====');

    // Generate timestamp for the zip file name
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final zipFileName = '$timestamp-purchase-app-data.zip';

    // Create archive
    final archive = Archive();

    // Export each table to CSV and add to archive
    for (final tableName in TableNames.allDataTables) {
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
      final rowData = columns.map((column) {
        final value = row[column];
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
  Future<void> shareExportedZip(String zipFilePath) async {
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
  Future<String> saveToDownloads(String zipFilePath) async {
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
  Future<Map<String, dynamic>> getExportSummary() async {
    final tables = [
      TableNames.currencies,
      TableNames.unitOfMeasures,
      TableNames.manufacturers,
      TableNames.vendors,
      TableNames.materials,
      TableNames.manufacturerMaterials,
      TableNames.vendorPriceLists,
      TableNames.projects,
      TableNames.baskets,
      TableNames.basketItems,
      TableNames.quotations,
      TableNames.quotationItems,
      TableNames.purchaseOrders,
      TableNames.purchaseOrderItems,
      TableNames.purchaseOrderPayments,
      TableNames.changeLog,
      TableNames.condensedChangeLog,
    ];

    final db = await _dbHelper.database;
    final summary = <String, int>{};
    int totalRows = 0;

    for (final tableName in tables) {
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

  /// Map of table names to their model factory constructors
  /// This allows us to use the model's fromMap method which knows the correct types
  final Map<String, Function(Map<String, dynamic>)> _modelFactories = {
    TableNames.currencies: (map) => Currency.fromMap(map),
    TableNames.unitOfMeasures: (map) => UnitOfMeasure.fromMap(map),
    TableNames.manufacturers: (map) => Manufacturer.fromMap(map),
    TableNames.vendors: (map) => Vendor.fromMap(map),
    TableNames.materials: (map) => Material.fromMap(map),
    TableNames.manufacturerMaterials: (map) =>
        ManufacturerMaterial.fromMap(map),
    TableNames.vendorPriceLists: (map) => VendorPriceList.fromMap(map),
    TableNames.projects: (map) => Project.fromMap(map),
    TableNames.baskets: (map) => Basket.fromMap(map),
    TableNames.basketItems: (map) => BasketItem.fromMap(map),
    TableNames.quotations: (map) => Quotation.fromMap(map),
    TableNames.quotationItems: (map) => QuotationItem.fromMap(map),
    TableNames.purchaseOrders: (map) => PurchaseOrder.fromMap(map),
    TableNames.purchaseOrderItems: (map) => PurchaseOrderItem.fromMap(map),
    TableNames.purchaseOrderPayments: (map) =>
        PurchaseOrderPayment.fromMap(map),
    TableNames.changeLog: (map) => ChangeLog.fromMap(map),
    TableNames.condensedChangeLog: (map) => CondensedChangeLog.fromMap(map),
  };

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
      final modelFactory = _modelFactories[tableName];

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

          // Pre-convert CSV strings to typed values for model factory
          final Map<String, dynamic> preTypedRecord =
              _preConvertTypes(rawRecord);

          // Convert to properly typed record using model's fromMap
          Map<String, dynamic> typedRecord;
          if (modelFactory != null) {
            try {
              // Use the model's fromMap to get proper types, then convert back to map
              final modelInstance = modelFactory(preTypedRecord);
              typedRecord = _modelToMap(modelInstance, tableName);
            } catch (e) {
              // If model factory fails, fall back to heuristic parsing
              final errorMsg =
                  'Row ${i + 1}: ${e.toString().split('\n').first}';
              errorMessages.add(errorMsg);

              typedRecord = _convertRecordTypes(rawRecord, headers);
            }
          } else {
            // No model factory available, use heuristic parsing
            typedRecord = _convertRecordTypes(rawRecord, headers);
          }

          // Check if record already exists (based on uuid or name)
          final primaryKey = typedRecord.containsKey('uuid') ? 'uuid' : 'name';
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

  /// Convert a model instance back to a map for database storage
  /// Uses the model's toMap method
  Map<String, dynamic> _modelToMap(dynamic modelInstance, String tableName) {
    // All our models have a toMap method
    if (modelInstance is Currency) return modelInstance.toMap();
    if (modelInstance is UnitOfMeasure) return modelInstance.toMap();
    if (modelInstance is Manufacturer) return modelInstance.toMap();
    if (modelInstance is Vendor) return modelInstance.toMap();
    if (modelInstance is Material) return modelInstance.toMap();
    if (modelInstance is ManufacturerMaterial) return modelInstance.toMap();
    if (modelInstance is VendorPriceList) return modelInstance.toMap();
    if (modelInstance is Project) return modelInstance.toMap();
    if (modelInstance is Basket) return modelInstance.toMap();
    if (modelInstance is BasketItem) return modelInstance.toMap();
    if (modelInstance is Quotation) return modelInstance.toMap();
    if (modelInstance is QuotationItem) return modelInstance.toMap();
    if (modelInstance is PurchaseOrder) return modelInstance.toMap();
    if (modelInstance is PurchaseOrderItem) return modelInstance.toMap();
    if (modelInstance is PurchaseOrderPayment) return modelInstance.toMap();
    if (modelInstance is ChangeLog) return modelInstance.toMap();
    if (modelInstance is CondensedChangeLog) return modelInstance.toMap();

    throw Exception('Unknown model type for table: $tableName');
  }

  /// Pre-convert CSV strings to types expected by model factories
  /// This handles int, bool conversions that models expect
  Map<String, dynamic> _preConvertTypes(Map<String, dynamic> rawRecord) {
    final Map<String, dynamic> converted = {};

    rawRecord.forEach((key, value) {
      if (value == null) {
        converted[key] = null;
        return;
      }

      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) {
        converted[key] = null;
        return;
      }

      // Handle known integer fields
      if (key == 'number_of_decimal_places' ||
          key == 'table_index' ||
          key.endsWith('_id') && key != 'uuid' ||
          key.contains('decimal_places') ||
          key.contains('size') ||
          key.contains('quantity')) {
        converted[key] = int.tryParse(stringValue);
        return;
      }

      // Handle boolean fields (keep as int 0/1 for SQLite)
      if (key.startsWith('is_') || key == 'active' || key == 'completed') {
        final boolValue = stringValue == '1' ||
            stringValue.toLowerCase() == 'true' ||
            stringValue.toLowerCase() == 'yes';
        converted[key] = boolValue ? 1 : 0;
        return;
      }

      // Handle decimal/double fields
      if (key.contains('price') ||
          key.contains('rate') ||
          key.contains('amount') ||
          key.contains('tax') ||
          key.contains('percent')) {
        converted[key] = double.tryParse(stringValue);
        return;
      }

      // Default: keep as string
      converted[key] = stringValue;
    });

    return converted;
  }

  /// Fallback method to convert record types using heuristics
  /// Used when model factory is not available or fails
  Map<String, dynamic> _convertRecordTypes(
      Map<String, dynamic> rawRecord, List<String> headers) {
    final Map<String, dynamic> typedRecord = {};

    for (String header in headers) {
      final value = rawRecord[header];
      typedRecord[header] = _parseValue(header, value);
    }

    return typedRecord;
  }

  /// Parse cell value based on column name/type (fallback heuristic method)
  /// Returns SQLite-compatible types: num, String, or Uint8List
  dynamic _parseValue(String columnName, dynamic cellValue) {
    if (cellValue == null) return null;

    final stringValue = cellValue.toString().trim();
    if (stringValue.isEmpty) return null;

    // Handle dates - return ISO8601 string
    if (columnName.contains('updated_at') ||
        columnName.contains('created_at') ||
        columnName.contains('_date')) {
      try {
        return DateTime.parse(stringValue).toIso8601String();
      } catch (e) {
        return DateTime.now().toUtc().toIso8601String();
      }
    }

    // Handle booleans - SQLite needs 0/1 (int), not true/false
    if (columnName.contains('is_') ||
        columnName == 'active' ||
        columnName == 'completed') {
      final boolValue = stringValue == '1' ||
          stringValue.toLowerCase() == 'true' ||
          stringValue.toLowerCase() == 'yes';
      return boolValue ? 1 : 0; // Convert to int for SQLite
    }

    // Handle integers
    if (columnName == 'table_index' ||
        (columnName.contains('_id') && columnName != 'uuid')) {
      return int.tryParse(stringValue);
    }

    if (columnName.contains('decimal_places') ||
        columnName.contains('size') ||
        columnName.contains('quantity')) {
      return int.tryParse(stringValue) ?? 0;
    }

    // Handle decimals/doubles
    if (columnName.contains('price') ||
        columnName.contains('rate') ||
        columnName.contains('amount') ||
        columnName.contains('tax') ||
        columnName.contains('percent')) {
      return double.tryParse(stringValue) ?? 0.0;
    }

    // Default: return as string
    return stringValue;
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
}
