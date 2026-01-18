import 'package:flutter/foundation.dart';
import 'package:purchase_app/base/model_definition.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:uuid/uuid.dart';
import '../services/database_helper.dart';
import '../base/data_definition.dart';
import '../base/change_modes.dart';

/// Utility class for change log operations
/// This is the Flutter equivalent of backend/google-app-script-code/changeLogUtils.js
class ChangeLogUtils {
  final DatabaseHelper _dbHelper;
  static const _uuid = Uuid();

  ChangeLogUtils(this._dbHelper);

  /// Initialize change_log with all existing records from data tables
  /// This is the Flutter equivalent of changeLog.initializeChangeLogFromDataTables()
  ///
  /// Clears existing change_log and condensed_change_log, then creates INSERT entries
  /// for all records in all sync-relevant tables.
  ///
  /// Returns a status message with count of records initialized
  Future<String> initializeChangeLogFromDataTables() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Clear all data from change_log and condensed_change_log
    await db.delete(TableNames.changeLog);
    await db.delete(TableNames.condensedChangeLog);

    final List<Map<String, dynamic>> changeLogRecords = [];

    // Iterate through all sync-relevant tables (defined in SyncConfig.tableIndices)
    final syncTables = DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
    ]);

    for (final tableName in syncTables) {
      final tableDefinition = DataDefinition.getModelDefinition(tableName)!;
      final keyColumn = tableDefinition.primaryKeyField?.tableFieldName;

      // Query all records from the table
      try {
        final records = await db.query(tableName);

        if (records.isEmpty) {
          debugPrint('Table "$tableName" has no data rows, skipping');
          continue;
        }

        // Create change log entries for all records
        for (final record in records) {
          final tableKey = record[keyColumn];
          final updatedAt = record['updated_at'] as String?;

          if (tableKey != null && tableKey.toString().trim().isNotEmpty) {
            changeLogRecords.add({
              'uuid': _uuid.v4(),
              'table_index': tableDefinition.tableIndex,
              'table_key': tableKey.toString(),
              'change_mode': ChangeModes.insert,
              'updated_at': updatedAt ?? now,
            });
          }
        }

        debugPrint('Processed ${records.length} records from "$tableName"');
      } catch (e) {
        debugPrint('ERROR processing table "$tableName": $e');
        continue;
      }
    }

    // Insert all records into change_log in batch
    if (changeLogRecords.isNotEmpty) {
      final batch = db.batch();
      for (final record in changeLogRecords) {
        batch.insert(TableNames.changeLog, record);
      }
      await batch.commit(noResult: true);
    }

    final lastSyncTimestamp = await getLastSyncTimestampByLog();
    await SettingsManager.instance.setLastSyncTimestamp(lastSyncTimestamp);

    final message =
        'Initialized change_log with ${changeLogRecords.length} total records';
    debugPrint(message);
    return message;
  }

  /// Prepare condensed change log from change_log
  /// This eliminates redundant changes and keeps only the first INSERT/UPDATE for each table_key
  /// Removes entries that were later deleted
  ///
  /// [sinceTimestamp] - Optional ISO8601 timestamp to filter changes
  /// Returns list of condensed change records
  Future<List<Map<String, dynamic>>> prepareCondensedChangeLogFromChangeLog(
      {String? sinceTimestamp}) async {
    final db = await _dbHelper.database;

    // Get all change log entries, optionally filtered by timestamp
    final List<Map<String, dynamic>> changeLogData;
    if (sinceTimestamp != null) {
      changeLogData = await db.query(
        TableNames.changeLog,
        where: 'updated_at > ?',
        whereArgs: [sinceTimestamp],
        orderBy: 'updated_at ASC',
      );
    } else {
      changeLogData = await db.query(
        TableNames.changeLog,
        orderBy: 'updated_at ASC',
      );
    }

    final Map<String, Map<String, Map<String, dynamic>>> tableChangeHistory =
        {};

    // Process each change in chronological order
    for (final row in changeLogData) {
      final tableIndex = row['table_index'] as int;
      final tableKey = row['table_key'] as String;
      final changeMode = row['change_mode'] as String;
      //final updatedAt = row['updated_at'] as String;

      final changeHistoryTableMemberName = tableIndex.toString();

      // Initialize table history if it doesn't exist
      tableChangeHistory.putIfAbsent(changeHistoryTableMemberName, () => {});

      if (changeMode == ChangeModes.insert ||
          changeMode == ChangeModes.update) {
        // INSERT or UPDATE: Keep only if this is the first occurrence
        if (!tableChangeHistory[changeHistoryTableMemberName]!
            .containsKey(tableKey)) {
          tableChangeHistory[changeHistoryTableMemberName]![tableKey] = row;
        }
      } else if (changeMode == ChangeModes.delete) {
        // DELETE: Remove any previous INSERT/UPDATE, or keep DELETE if no prior change
        final oldRec =
            tableChangeHistory[changeHistoryTableMemberName]![tableKey];

        if (oldRec != null &&
            (oldRec['change_mode'] == ChangeModes.insert ||
                oldRec['change_mode'] == ChangeModes.update)) {
          // Previous INSERT/UPDATE exists, remove it (net effect is no change)
          tableChangeHistory[changeHistoryTableMemberName]!.remove(tableKey);
        } else if (oldRec != null &&
            oldRec['change_mode'] == ChangeModes.delete) {
          // Previous DELETE exists, keep the old one (ignore this duplicate delete)
        } else {
          // No previous change, keep this DELETE
          tableChangeHistory[changeHistoryTableMemberName]![tableKey] = row;
        }
      }
    }

    // Flatten the results
    final List<Map<String, dynamic>> result = [];
    for (final tableHistory in tableChangeHistory.values) {
      result.addAll(tableHistory.values);
    }

    // Sort by table_index (ascending), then by updated_at (ascending)
    result.sort((a, b) {
      final tableIndexCompare =
          (a['table_index'] as int).compareTo(b['table_index'] as int);
      if (tableIndexCompare != 0) return tableIndexCompare;
      return (a['updated_at'] as String).compareTo(b['updated_at'] as String);
    });

    return result;
  }

  /// Write condensed change log to condensed_change_log table
  ///
  /// [sinceTimestamp] - Optional ISO8601 timestamp to filter changes
  /// Returns count of records written
  Future<int> writeCondensedChangeLog({String? sinceTimestamp}) async {
    final db = await _dbHelper.database;

    // Clear existing condensed_change_log data
    await db.delete(TableNames.condensedChangeLog);

    // Get condensed change log data
    final condensedData = await prepareCondensedChangeLogFromChangeLog(
        sinceTimestamp: sinceTimestamp);

    // Write condensed data in batch
    if (condensedData.isNotEmpty) {
      final batch = db.batch();
      for (final record in condensedData) {
        batch.insert(TableNames.condensedChangeLog, record);
      }
      await batch.commit(noResult: true);
    }

    debugPrint(
        'Wrote ${condensedData.length} records to ${TableNames.condensedChangeLog}');
    return condensedData.length;
  }

  /// Write condensed change log for all data (no timestamp filter)
  /// Returns count of records written
  Future<int> writeCondensedChangeLogForAllData() async {
    // Use a very old timestamp to include all records
    return await writeCondensedChangeLog(
        sinceTimestamp: '1970-01-01T00:00:00.000Z');
  }

  /// Read condensed change log with pagination
  ///
  /// [offset] - Starting row index (0-based, relative to data rows)
  /// [limit] - Number of rows to read
  /// Returns a map with 'log' (array of change records) and 'totalRecords' (total count)
  Future<Map<String, dynamic>> readCondensedChangeLog({
    required int offset,
    required int limit,
  }) async {
    final db = await _dbHelper.database;

    // Get total count
    final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${TableNames.condensedChangeLog}');
    final totalRecords = countResult.first['count'] as int? ?? 0;

    if (totalRecords == 0) {
      return {'log': [], 'totalRecords': 0};
    }

    // Validate offset
    if (offset >= totalRecords || offset < 0) {
      return {'log': [], 'totalRecords': totalRecords};
    }

    // Calculate actual limit
    final actualLimit =
        (offset + limit > totalRecords) ? totalRecords - offset : limit;

    // Read the data range
    final data = await db.query(
      TableNames.condensedChangeLog,
      limit: actualLimit,
      offset: offset,
      orderBy: 'table_index ASC, updated_at ASC',
    );

    debugPrint('Read ${data.length} records from condensed_change_log '
        '(offset: $offset, limit: $limit, total: $totalRecords)');

    return {
      'log': data,
      'totalRecords': totalRecords,
    };
  }

  /// Log a single change to the change_log table
  ///
  /// [tableName] - Name of the table
  /// [tableKey] - Primary key value of the record
  /// [changeMode] - 'I', 'U', or 'D'
  /// [updatedAt] - Optional timestamp (defaults to now)
  Future<void> logChange({
    required String tableName,
    required String tableKey,
    required String changeMode,
    DateTime? updatedAt,
  }) async {
    final db = await _dbHelper.database;
    final tableDefinition = DataDefinition.getModelDefinition(tableName);
    if (tableDefinition == null) {
      debugPrint(
          'WARNING: No table index for $tableName, skipping change logging');
      return;
    }

    try {
      final now = updatedAt ?? DateTime.now();
      await db.insert(TableNames.changeLog, {
        'uuid': _uuid.v4(),
        'table_index': tableDefinition.tableIndex,
        'table_key': tableKey,
        'change_mode': changeMode,
        'updated_at': now.toIso8601String(),
      });
    } catch (error) {
      debugPrint('ERROR logging change: $error');
    }
  }

  /// Log multiple changes to the change_log table (batch operation)
  ///
  /// [tableName] - Name of the table
  /// [tableKeys] - Array of primary key values of the records
  /// [changeMode] - 'I', 'U', or 'D'
  /// [updatedAt] - Optional timestamp (defaults to now)
  Future<void> logChanges({
    required String tableName,
    required List<String> tableKeys,
    required String changeMode,
    DateTime? updatedAt,
  }) async {
    if (tableKeys.isEmpty) {
      return;
    }

    final db = await _dbHelper.database;
    final tableDefinition = DataDefinition.getModelDefinition(tableName);
    if (tableDefinition == null) {
      debugPrint(
          'WARNING: No table index for $tableName, skipping change logging');
      return;
    }

    try {
      final now = updatedAt ?? DateTime.now();
      final batch = db.batch();

      for (final tableKey in tableKeys) {
        batch.insert(TableNames.changeLog, {
          'uuid': _uuid.v4(),
          'table_index': tableDefinition.tableIndex,
          'table_key': tableKey,
          'change_mode': changeMode,
          'updated_at': now.toIso8601String(),
        });
      }

      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint('ERROR logging changes: $error');
    }
  }

  /// Insert a single record into change_log
  ///
  /// [tableIndex] - Table index
  /// [tableKey] - Primary key value
  /// [changeMode] - 'I', 'U', or 'D'
  /// [updatedAt] - Optional timestamp (defaults to now)
  Future<void> insertRecord({
    required int tableIndex,
    required String tableKey,
    required String changeMode,
    DateTime? updatedAt,
  }) async {
    final db = await _dbHelper.database;

    try {
      final now = updatedAt ?? DateTime.now();
      await db.insert(TableNames.changeLog, {
        'uuid': _uuid.v4(),
        'table_index': tableIndex,
        'table_key': tableKey,
        'change_mode': changeMode,
        'updated_at': now.toIso8601String(),
      });
    } catch (error) {
      debugPrint('ERROR inserting change record: $error');
    }
  }

  /// Insert multiple records into change_log (batch operation)
  ///
  /// [records] - List of change records to insert
  /// Each record should have: uuid (optional), table_index, table_key, change_mode, updated_at (optional)
  Future<void> insertRecords(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) {
      return;
    }

    final db = await _dbHelper.database;

    try {
      final now = DateTime.now();
      final batch = db.batch();

      for (final rec in records) {
        batch.insert(TableNames.changeLog, {
          'uuid': rec['uuid'] ?? _uuid.v4(),
          'table_index': rec['table_index'],
          'table_key': rec['table_key'],
          'change_mode': rec['change_mode'] ?? ChangeModes.insert,
          'updated_at': rec['updated_at'] ?? now,
        });
      }

      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint('ERROR inserting change records: $error');
    }
  }

  /// Get the maximum updated_at timestamp from change_log
  ///
  /// Returns the last sync timestamp or null if no records exist
  Future<String?> getLastSyncTimestampByLog() async {
    final db = await _dbHelper.database;

    debugPrint('[ChangeLog] Getting last sync timestamp from change_log...');
    final result = await db.rawQuery(
      'SELECT MAX(updated_at) as max_updated_at FROM ${TableNames.changeLog}',
    );

    final lastSyncTimestamp =
        result.isNotEmpty ? result.first['max_updated_at'] as String? : null;

    if (lastSyncTimestamp != null) {
      debugPrint('[ChangeLog] Last sync timestamp: $lastSyncTimestamp');
    } else {
      debugPrint('[ChangeLog] No sync timestamp found (change_log is empty)');
    }

    return lastSyncTimestamp;
  }
}
