const deltaSync = {
    /**
     * Insert or update records in a sheet
     * Uses KEY_COLUMN as primary key for upsert logic
     */
    upsertRecords(tableName, records) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);
        const tableDef = tableDefinitions.getByName(tableName);

        if (!sheet) {
            throw new Error(`Sheet "${tableName}" not found`);
        }
        if (!tableDef) {
            throw new Error(`Schema for "${tableName}" not found`);
        }

        // Get column map from actual sheet headers
        const columnMap = setup.getSheetColumnMap(sheet, tableName);
        
        const data = sheet.getDataRange().getValues();
        let updatedCount = 0;
        const keyColumn = tableDef.keyColumn;
        const keyColumnIndex = columnMap[keyColumn];

        if (keyColumnIndex === undefined) {
            throw new Error(`Key column "${keyColumn}" not found in sheet "${tableName}"`);
        }

        for (const record of records) {
            const keyValue = record[keyColumn];
            let rowIndex = -1;

            // Find existing row by key column using actual column index from sheet
            for (let i = 1; i < data.length; i++) {
                if (data[i][keyColumnIndex] === keyValue) {
                    rowIndex = i + 1; // +1 because sheet rows are 1-indexed
                    break;
                }
            }

            // Build row data using column map
            const rowData = utils.buildRowDataFromRecord(record, tableDef?.columnNames, columnMap, tableName);
            const numCols = Math.max(...Object.values(columnMap)) + 1;

            if (rowIndex > 0) {
                // Update existing row
                const range = sheet.getRange(rowIndex, 1, 1, numCols);
                range.setValues([rowData]);
            } else {
                // Check if row 2 exists and is blank (empty key)
                if (data.length >= 2 && (!data[1][keyColumnIndex] || data[1][keyColumnIndex].toString().trim() === '')) {
                    // Use the blank row 2 instead of appending
                    const range = sheet.getRange(2, 1, 1, numCols);
                    range.setValues([rowData]);
                    // Update data array to reflect the change
                    data[1] = rowData;
                } else {
                    // Append new row
                    sheet.appendRow(rowData);
                    // Update data array to reflect the append
                    data.push(rowData);
                }
            }

            updatedCount++;
        }

        // Optimize column widths after updates
        // utils.autoResizeSheetColumns(sheet);

        return updatedCount;
    },

    /**
     * Delete records from a sheet
     * @param {string} tableName - Name of the table
     * @param {Array} deletions - Array of {keyValue, deleted_at} objects where keyValue is the primary key
     * @returns {number} Number of records deleted
     */
    deleteRecords(tableName, deletions) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);
        const tableDef = tableDefinitions.getByName(tableName);

        if (!sheet) {
            throw new Error(`Sheet "${tableName}" not found`);
        }
        if (!tableDef) {
            throw new Error(`Schema for "${tableName}" not found`);
        }

        // Get column map from actual sheet headers
        const columnMap = setup.getSheetColumnMap(sheet, tableName);
        const keyColumn = tableDef.keyColumn;
        const keyColumnIndex = columnMap[keyColumn];

        if (keyColumnIndex === undefined) {
            throw new Error(`Key column "${keyColumn}" not found in sheet "${tableName}"`);
        }

        const data = sheet.getDataRange().getValues();
        let deletedCount = 0;

        // Process each deletion
        for (const deletion of deletions) {
            const keyValue = deletion.keyValue;
            let rowIndex = -1;

            // Find existing row by key column using actual column index from sheet
            for (let i = 1; i < data.length; i++) {
                if (data[i][keyColumnIndex] === keyValue) {
                    rowIndex = i + 1; // +1 because sheet rows are 1-indexed
                    break;
                }
            }

            if (rowIndex > 0) {
                // Delete the row
                sheet.deleteRows(rowIndex, 1);
                deletedCount++;

                // Update data array to reflect deletion
                data.splice(rowIndex - 1, 1);
            }
        }

        return deletedCount;
    },

    /**
     * Apply delta changes from client to server with batch processing
     * Processes deletes first, then inserts/updates in batches per table
     * @param {array} log - Array of change log entries
     * @param {object} tableRecords - Map of table names to record maps
     * @returns {number} Number of changes processed
     */
    applyDeltaChangesBatch(log, tableRecords) {
        const now = new Date();
        let processed = 0;

        // Group changes by table and operation
        const changesByTable = {};

        for (const change of log) {
            try {
                const tableIndex = change.table_index;
                const table_key = change.table_key;
                const changeMode = change.change_mode;
                const updatedAt = new Date(utils.getEpochTimeMilliseconds(change.updated_at, now));

                // Find table name from index
                const tableName = tableDefinitions.getTableNameByIndex(tableIndex);
                if (!tableName) {
                    Logger.log(`Unknown table index: ${tableIndex}`);
                    continue;
                }

                // Initialize table structure
                if (!changesByTable[tableName]) {
                    changesByTable[tableName] = {
                        deletes: [],
                        upserts: []
                    };
                }

                if (changeMode === CHANGE_MODE_DELETE) {
                    changesByTable[tableName].deletes.push({ keyValue: table_key, deleted_at: updatedAt });
                } else {
                    // For insert/update, get record from tableRecords
                    const record = tableRecords?.[tableName]?.[table_key];
                    if (record) {
                        record[CHANGE_MODE_TEMPORARY_FIELD] = changeMode; // Store change mode temporarily if needed
                        record[UPDATED_AT_TEMPORARY_FIELD] = updatedAt;
                        record.updated_at = new Date(utils.getEpochTimeMilliseconds(record.updated_at, updatedAt)); // Ensure updated_at is Date object
                        changesByTable[tableName].upserts.push(record);
                    }
                }
            } catch (error) {
                Logger.log(`ERROR grouping change: ${error.toString()}`);
            }
        }

        // Process each table: deletes first, then upserts
        for (const tableName in changesByTable) {
            const changes = changesByTable[tableName];
            const tableIndex = tableDefinitions.getTableIndexByName(tableName);

            try {
                // Process deletes
                if (changes.deletes.length > 0) {
                    Logger.log(`Deleting ${changes.deletes.length} records from ${tableName}`);
                    const deleted = this.deleteRecords(tableName, changes.deletes);
                    processed += deleted;

                    const tableDef = tableDefinitions.getByName(tableName);
                    const keyColumn = tableDef.keyColumn;
                    const changeLogs = [];
                    // Log changes
                    for (const deletion of changes.deletes) {
                        changeLogs.push({
                            uuid: utils.UUID(),
                            table_index: tableIndex,
                            table_key: deletion.keyValue,
                            change_mode: CHANGE_MODE_DELETE,
                            updated_at: deletion.deleted_at
                        });
                    }
                    changeLog.insertRecords(changeLogs);
                }

                // Process upserts
                if (changes.upserts.length > 0) {
                    Logger.log(`Upserting ${changes.upserts.length} records to ${tableName}`);
                    const upserted = this.upsertRecords(tableName, changes.upserts);
                    processed += upserted;

                    const tableDef = tableDefinitions.getByName(tableName);
                    const keyColumn = tableDef.keyColumn;
                    const changeLogs = [];
                    // Log changes
                    for (const record of changes.upserts) {
                        changeLogs.push({
                            uuid: utils.UUID(),
                            table_index: tableIndex,
                            table_key: record[keyColumn],
                            change_mode: record[CHANGE_MODE_TEMPORARY_FIELD] || CHANGE_MODE_INSERT,
                            updated_at: record[UPDATED_AT_TEMPORARY_FIELD] || now
                        });
                    }
                    changeLog.insertRecords(changeLogs);
                }
            } catch (error) {
                Logger.log(`ERROR processing table ${tableName}: ${error.toString()}`);
            }
        }

        return processed;
    },

    /**
     * Fetch table records efficiently for a list of changes
     * Groups changes by table and fetches all records in batch
     * @param {array} log - Array of change log entries
     * @returns {object} Object with table names as keys and record maps as values
     */
    fetchTableRecordsForChanges(log) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const tableRecords = {};

        // Group changes by table_index
        const changesByTable = {};
        for (const change of log) {
            const tableIndex = change.table_index;
            const changeMode = change.change_mode;
            const table_key = change.table_key;

            // Only fetch records for insert/update operations
            if (changeMode === CHANGE_MODE_INSERT || changeMode === CHANGE_MODE_UPDATE) {
                if (!changesByTable[tableIndex]) {
                    changesByTable[tableIndex] = [];
                }
                changesByTable[tableIndex].push(table_key);
            }
        }

        // Fetch records for each table
        for (const tableIndexStr in changesByTable) {
            const tableIndex = parseInt(tableIndexStr, 10);
            const tableName = tableDefinitions.getTableNameByIndex(tableIndex);

            if (!tableName) {
                Logger.log(`WARNING: Unknown table index ${tableIndex}`);
                continue;
            }

            const table_keys = changesByTable[tableIndex];
            if (table_keys.length === 0) continue;

            const sheet = ss.getSheetByName(tableName);
            if (!sheet) {
                Logger.log(`WARNING: Sheet "${tableName}" not found`);
                continue;
            }

            const tableDef = tableDefinitions.getByName(tableName);
            if (!tableDef) {
                Logger.log(`WARNING: No metadata for table "${tableName}"`);
                continue;
            }

            // Fetch all records for this table efficiently
            const records = this.batchGetRecordsByKeys(sheet, tableName, table_keys);

            if (Object.keys(records).length > 0) {
                tableRecords[tableName] = records;
            }
        }

        for (let i = log.length - 1; i >= 0; i--) {
            const change = log[i];
            const tableIndex = change.table_index;
            const changeMode = change.change_mode;
            const table_key = change.table_key;
            const tableName = tableDefinitions.getTableNameByIndex(tableIndex);

            // Only fetch records for insert/update operations
            if (changeMode === CHANGE_MODE_INSERT || changeMode === CHANGE_MODE_UPDATE) {
                if (!tableRecords?.[tableName]?.[table_key]) {
                    Logger.log(`WARNING: Record with key ${table_key} not found in table ${tableName}`);
                    log.splice(i, 1);
                }
            }
        }

        return tableRecords;
    },

    /**
     * Batch fetch records by primary keys for performance
     * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet - Google Sheet object
     * @param {string} tableName - Name of the table
     * @param {array} keys - Array of primary key values to fetch
     * @returns {object} Map of key value to record objects
     */
    batchGetRecordsByKeys(sheet, tableName, keys) {
        const records = {};
        const tableDef = tableDefinitions.getByName(tableName);
        const columnTypes = tableDef?.columnTypes;
        const columnMap = setup.getSheetColumnMap(sheet, tableName);
        const keyColumn = tableDef?.keyColumn;

        if (!keyColumn || columnMap?.[keyColumn] === undefined) {
            return records;
        }

        const lastRow = sheet.getLastRow();
        if (lastRow < 2) {
            return records; // No data rows
        }

        const numCols = Math.max(...Object.values(columnMap)) + 1;
        // Read all data at once for efficiency
        const sheetData = sheet.getRange(2, 1, lastRow - 1, numCols).getValues();
        // Create a set for faster lookup
        const keySet = new Set(keys);

        // Find matching rows
        for (let i = 0; i < sheetData.length; i++) {
            const row = sheetData[i];
            const keyValue = row[columnMap[keyColumn]];

            if (keySet.has(keyValue)) {
                const record = {};
                for (const colName in columnTypes) {
                    let val = row[columnMap?.[colName]];

                    // @ts-ignore
                    if (columnTypes?.[colName] === DATA_TYPES.TIME_STAMP && val && val instanceof Date) {
                        // Convert Date objects to ISO strings
                        val = val.toISOString();
                        //Is this necessary?
                        //JSON serialization automatically converts Date to ISO string
                    }
                    record[colName] = val;
                }
                records[keyValue] = record;
                if (!record.updated_at) {
                    record.updated_at = new Date().toISOString();
                }
            }
        }

        return records;
    }
};
