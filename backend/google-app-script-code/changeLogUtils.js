const changeLog = {
    /**
     * Initialize change_log sheet with all existing records
     * Clears existing change_log and creates INSERT entries for all records in all tables
     * @returns {string} Status message with count of records initialized
     */
    initializeChangeLogFromDataSheets() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const changeLogSheet = ss.getSheetByName(TABLES.change_log);
        const now = new Date();

        if (!changeLogSheet) {
            throw new Error(`${TABLES.change_log} sheet not found. Run setup() first.`);
        }

        // Clear all data except header row
        cleanup.cleanupSheet(TABLES.change_log);
        cleanup.cleanupSheet(TABLES.condensed_change_log);

        const dataTable = [];

        // Iterate through all tables defined in TABLE_NAMES_TO_INDICES
        for (const sheetName of tableDefinitions.syncRelevantTableNames) {
            const sheet = ss.getSheetByName(sheetName);
            if (!sheet) {
                Logger.log(`WARNING: Sheet "${sheetName}" not found, skipping`);
                continue;
            }

            const tableIndex = tableDefinitions.getTableIndexByName(sheetName);
            const tableDef = tableDefinitions.getByName(sheetName);
            const keyColumn = tableDef.keyColumn;
            const columnMap = setup.getSheetColumnMap(sheet, sheetName);

            const sheetLastRow = sheet.getLastRow();
            if (sheetLastRow < 2) {
                // No data rows
                Logger.log(`Sheet "${sheetName}" has no data rows, skipping`);
                continue;
            }

            const keyColumnIndex = columnMap?.[keyColumn];
            const updatedAtColumnIndex = columnMap?.updated_at;

            // Read key column values (skip header row)
            const tableKeyValues = sheet.getRange(2, keyColumnIndex + 1, sheetLastRow - 1, 1).getValues();
            // Read updated_at column values (skip header row)
            const updatedAtValues = sheet.getRange(2, updatedAtColumnIndex + 1, sheetLastRow - 1, 1).getValues();

            // Prepare data for change_log
            for (let i = 0; i < tableKeyValues.length; i++) {
                const table_key = tableKeyValues[i][0];
                const updatedAt = updatedAtValues[i][0];
                if (table_key && typeof table_key === "string" && table_key.trim() !== "") {
                    dataTable.push([utils.UUID(), tableIndex, table_key, CHANGE_MODE_INSERT, updatedAt || now]);
                }
            }

            Logger.log(`Processed ${tableKeyValues.length} records from "${sheetName}"`);
        }

        // Insert all records into change_log
        if (dataTable.length > 0) {
            changeLogSheet.getRange(2, 1, dataTable.length,
                tableDefinitions.getByName(TABLES.change_log).columnCount
            ).setValues(dataTable);
        }

        setup.setupDataTableSheet(TABLES.change_log, false);

        Logger.log(`Initialized change_log with ${dataTable.length} total records`);
        return `Initialized change_log with ${dataTable.length} total records`;
    },

    /**
     * Get condensed change log that eliminates redundant changes
     * Keeps only the first INSERT/UPDATE for each table_key and removes entries that were later deleted
     * @param {number} sinceEpochTimeMilliseconds - Timestamp filter in milliseconds (optional)
    * @returns {array} Array of condensed change records
     */
    prepareCondensedChangeLogFromChangeLog(sinceEpochTimeMilliseconds) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(TABLES.change_log);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.change_log);

        if (!sheet) {
            return [];
        }

        const data = sheet.getDataRange().getValues();
        const result = [];
        const tableChangeHistory = {};

        // Skip header row (index 0)
        for (let i = 1; i < data.length; i++) {
            const row = data[i];
            const updated_at_milliseconds = utils.getEpochTimeMilliseconds(
                row[columnMap.updated_at],
                EPOCH_TIME_1900_01_01_00_00_00_UTC_MILLISECONDS);
            const rec = {
                uuid: row[columnMap?.uuid],
                table_index: row[columnMap?.table_index],
                table_key: row[columnMap?.table_key],
                change_mode: row[columnMap?.change_mode],
                updated_at: new Date(updated_at_milliseconds),
                updated_at_milliseconds: updated_at_milliseconds,
            };

            // Filter by timestamp if provided
            if (rec.updated_at_milliseconds <= sinceEpochTimeMilliseconds) {
                continue;
            }

            const changeHistoryTableMemberName = String(rec.table_index);

            // Initialize table history if it doesn't exist
            if (!tableChangeHistory[changeHistoryTableMemberName]) {
                tableChangeHistory[changeHistoryTableMemberName] = {};
            }

            const table_key = rec.table_key;

            if (rec.change_mode === CHANGE_MODE_INSERT || rec.change_mode === CHANGE_MODE_UPDATE) {
                const oldRec = tableChangeHistory[changeHistoryTableMemberName][table_key]
                if (!oldRec) {
                    tableChangeHistory[changeHistoryTableMemberName][table_key] = rec;
                }
            } else if (rec.change_mode === CHANGE_MODE_DELETE) {
                const oldRec = tableChangeHistory[changeHistoryTableMemberName][table_key]
                if (oldRec && (oldRec.change_mode === CHANGE_MODE_INSERT || oldRec.change_mode === CHANGE_MODE_UPDATE)) {
                    delete tableChangeHistory[changeHistoryTableMemberName][table_key];
                } else if (oldRec && (oldRec.change_mode === CHANGE_MODE_DELETE)) {
                } else {
                    tableChangeHistory[changeHistoryTableMemberName][table_key] = rec;
                }
            }
        }

        for (const changeHistoryTableMemberName in tableChangeHistory) {
            const tableHistory = tableChangeHistory[changeHistoryTableMemberName];
            for (const table_key in tableHistory) {
                result.push(tableHistory[table_key]);
            }
        }

        // Sort by table_index (ascending), then by updated_at (ascending)
        result.sort((a, b) => {
            if (a.table_index !== b.table_index) {
                return a.table_index - b.table_index;
            }
            const aTime = a.updated_at_milliseconds;
            const bTime = b.updated_at_milliseconds;
            return aTime - bTime;
        });

        return result;
    },

    /**
     * Write condensed change log to condensed_change_log sheet
     * Creates the sheet if it doesn't exist and writes all condensed records
     * @param {number} sinceEpochTimeMilliseconds - Timestamp filter in milliseconds (optional)
    * @returns {number} count of records written
     */
    writeCondensedChangeLog(sinceEpochTimeMilliseconds) {
        // Clear existing data (except header)
        cleanup.cleanupSheet(TABLES.condensed_change_log);
        const ss = SpreadsheetApp.getActiveSpreadsheet();

        // Get condensed change log data
        const condensedData = this.prepareCondensedChangeLogFromChangeLog(sinceEpochTimeMilliseconds);

        // Get or create condensed_change_log sheet
        let condensedSheet = ss.getSheetByName(TABLES.condensed_change_log);
        if (!condensedSheet) {
            Logger.log(`${TABLES.condensed_change_log} sheet does not exist`);
        }

        // Write condensed data
        if (condensedData.length > 0) {
            const dataTable = condensedData.map(rec => [
                rec.uuid,
                rec.table_index,
                rec.table_key,
                rec.change_mode,
                rec.updated_at
            ]);

            condensedSheet.getRange(2, 1, dataTable.length,
                tableDefinitions.getByName(TABLES.condensed_change_log).columnCount
            ).setValues(dataTable);
        }
        //setup.setupDataTableSheet(TABLE_NAMES.condensed_change_log, false);
        Logger.log(`Wrote ${condensedData.length} records to ${TABLES.condensed_change_log}`);
        return condensedData.length;
    },

    writeCondensedChangeLogForAllData() {
        return this.writeCondensedChangeLog(EPOCH_TIME_LOWEST_MILLISECONDS);
    },

    /**
     * Read condensed change log with pagination
     * @param {number} offset - Starting row index (0-based, relative to data rows)
     * @param {number} limit - Number of rows to read
     * @return {object} {log: array of change records, totalRecords: total count}
     */
    readCondensedChangeLog(offset, limit) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(TABLES.condensed_change_log);
        const tableDef = tableDefinitions.getByName(TABLES.condensed_change_log);
        const colIdx = tableDef?.columnIndices;
        const now = new Date();

        if (!sheet) {
            Logger.log('condensed_change_log sheet not found');
            return { log: [], totalRecords: 0 };
        }

        const lastRow = sheet.getLastRow();
        if (lastRow <= 1) {
            // Only header or empty sheet
            return { log: [], totalRecords: 0 };
        }

        const totalRecords = lastRow - 1; // Exclude header row

        // Calculate actual range to read (offset is 0-based for data rows)
        const startRow = 2 + offset; // Row 1 is header, row 2 is first data row
        const endRow = Math.min(startRow + limit - 1, lastRow);
        const numRows = endRow - startRow + 1;

        if (startRow > lastRow || numRows <= 0) {
            // Offset is beyond available data
            return { log: [], totalRecords: totalRecords };
        }

        // Read the data range
        const data = sheet.getRange(startRow, 1, numRows, tableDef.columnCount).getValues();

        // Convert to array of objects
        const log = data.map(row => ({
            uuid: row[colIdx?.uuid],
            table_index: row[colIdx?.table_index],
            table_key: row[colIdx?.table_key],
            change_mode: row[colIdx?.change_mode],
            updated_at: row[colIdx?.updated_at] || now
        }));

        Logger.log(`Read ${log.length} records from condensed_change_log (offset: ${offset}, limit: ${limit}, total: ${totalRecords})`);

        return {
            log: log,
            totalRecords: totalRecords
        };
    },

    /**
     * Log a change to the change_log sheet for delta sync
     * @param {string} tableName - Name of the table
     * @param {string} table_key - Primary key value of the record
     * @param {string} changeMode - 'I', 'U', or 'D'
     * @param {Date} updatedAt - Timestamp of the update
     */
    logChange(tableName, table_key, changeMode, updatedAt) {
        try {
            const ss = SpreadsheetApp.getActiveSpreadsheet();
            const changeLogSheet = ss.getSheetByName(TABLES.change_log);

            if (!changeLogSheet) {
                Logger.log(
                    "WARNING: change_log sheet not found, skipping change logging"
                );
                return;
            }

            const tableIndex = tableDefinitions.getTableIndexByName(tableName);
            if (tableIndex === undefined) {
                Logger.log(`WARNING: No table index for ${tableName}`);
                return;
            }

            const now = new Date();
            changeLogSheet.appendRow([utils.UUID(), tableIndex, table_key, changeMode, updatedAt || now]);
        } catch (error) {
            Logger.log(`ERROR logging change: ${error.toString()}`);
        }
    },

    /**
     * Log multiple changes to the change_log sheet for delta sync (batch operation)
     * @param {string} tableName - Name of the table
     * @param {string[]} table_keys - Array of primary key values of the records
     * @param {string} changeMode - 'I', 'U', or 'D'
     * @param {Date} updatedAt - Timestamp of the update
     */
    logChanges(tableName, table_keys, changeMode, updatedAt) {
        try {
            if (!table_keys || table_keys.length === 0) {
                return;
            }

            const ss = SpreadsheetApp.getActiveSpreadsheet();
            const changeLogSheet = ss.getSheetByName(TABLES.change_log);

            if (!changeLogSheet) {
                Logger.log(
                    "WARNING: change_log sheet not found, skipping change logging"
                );
                return;
            }

            const tableIndex = tableDefinitions.getTableIndexByName(tableName);
            if (tableIndex === undefined) {
                Logger.log(`WARNING: No table index for ${tableName}`);
                return;
            }

            const now = updatedAt || new Date();

            // Build rows for batch append
            const rows = table_keys.map(table_key => [utils.UUID(), tableIndex, table_key, changeMode, now]);

            // Append all rows in one operation for better performance
            if (rows.length > 0) {
                const startRow = changeLogSheet.getLastRow() + 1;
                changeLogSheet.getRange(startRow, 1, rows.length,
                    tableDefinitions.getByName(TABLES.change_log).columnCount
                ).setValues(rows);
            }
        } catch (error) {
            Logger.log(`ERROR logging changes: ${error.toString()}`);
        }
    },
    /**
     * @param {number} tableIndex
     * @param {any} table_key
     * @param {string} changeMode
     * @param {Date} updatedAt
     */
    insertRecord(tableIndex, table_key, changeMode, updatedAt) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const changeLogSheet = ss.getSheetByName(TABLES.change_log);

        if (!changeLogSheet) {
            Logger.log(
                "WARNING: change_log sheet not found, skipping change logging"
            );
            return;
        }
        const now = new Date();
        changeLogSheet.appendRow([utils.UUID(), tableIndex, table_key, changeMode, updatedAt || now]);
    },
    /**
     * @param {{ uuid: any; table_index: any; table_key: any; change_mode: any; updated_at: any; }[]} records
     */
    insertRecords(records) {
        if (!records || records.length === 0) {
            return;
        }

        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const changeLogSheet = ss.getSheetByName(TABLES.change_log);

        if (!changeLogSheet) {
            Logger.log(
                "WARNING: change_log sheet not found, skipping change logging"
            );
            return;
        }

        const now = new Date();

        // Build rows for batch append
        const rows = records.map((
            /** @type {{ uuid: string; table_index: number; table_key: string; change_mode: string; updated_at: Date|any; }} */ 
            rec) => [
            rec.uuid || utils.UUID(),
            rec.table_index,
            rec.table_key,
            rec.change_mode || CHANGE_MODE_INSERT,
            rec.updated_at || now
        ]);

        // Append all rows in one operation for better performance
        if (rows.length > 0) {
            const startRow = changeLogSheet.getLastRow() + 1;
            changeLogSheet.getRange(startRow, 1, rows.length,
                tableDefinitions.getByName(TABLES.change_log).columnCount
            ).setValues(rows);
        }
    },
};