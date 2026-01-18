const cleanup = {
    /**
     * Cleanup a single sheet by clearing all data rows (keeps header)
     * @param {string} sheetName - Name of the sheet to cleanup
     * @returns {number} Number of rows cleared (0 if sheet not found or already empty)
     */
    cleanupSheet(sheetName) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(sheetName);

        if (!sheet) {
            Logger.log(`WARNING: Sheet "${sheetName}" not found`);
            return 0;
        }

        const lastRow = sheet.getMaxRows();

        // If there are data rows (more than just the header)
        if (lastRow > 1) {
            const numRowsToClear = lastRow - 1;
            const numCols = sheet.getLastColumn();

            // Clear the content of data rows (keep the rows but remove content)
            sheet.getRange(2, 1, numRowsToClear, numCols).clearContent();

            Logger.log(`Cleared ${numRowsToClear} rows from ${sheetName}`);

            // Delete all rows after the header row
            if (lastRow > 2) {
                sheet.deleteRows(3, lastRow - 2);
                Logger.log(`Deleted ${lastRow - 1} rows from ${sheetName}`);
            }

            return numRowsToClear;
        } else {
            Logger.log(`${sheetName} is already empty`);
            return 0;
        }
    },

    /**
     * Cleanup function to clear all data from data sheets
     * Keeps the config sheet and its APP_CODE intact
     * Only clears data rows (keeps headers)
     */
    cleanup() {
        let clearedCount = 0;
        let totalRowsCleared = 0;

        for (const sheetName of tableDefinitions.tableNames) {
            const rowsCleared = this.cleanupSheet(sheetName);
            if (rowsCleared > 0) {
                clearedCount++;
                totalRowsCleared += rowsCleared;
            }
        }

        Logger.log(
            `Cleanup completed! Cleared ${totalRowsCleared} total rows from ${clearedCount} sheets.`
        );
        Logger.log("Config sheet preserved.");

        return `Cleanup completed! Cleared ${totalRowsCleared} total rows from ${clearedCount} data sheets. Config sheet preserved.`;
    },

    /**
     * Cleanup the current active sheet by clearing all data rows (keeps header)
     * Wrapper function for menu item that calls cleanupSheet()
     */
    cleanupCurrentSheet() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getActiveSheet();
        const sheetName = sheet.getName();

        const rowsCleared = this.cleanupSheet(sheetName);

        const message = rowsCleared > 0
            ? `Cleared ${rowsCleared} rows from ${sheetName}`
            : `${sheetName} is already empty`;

        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast(message);
        }
        return message;
    },

    /**
     * Cleanup transaction data sheets only
     * Dynamically identifies and clears transaction data sheets from TABLE_DEFINITIONS
     * Keeps master data sheets (manufacturers, vendors, materials, etc.) intact
     * @returns {string} Summary message of the cleanup operation
     */
    cleanupTransactionDataSheets() {
        // Dynamically get transaction sheets from TABLE_DEFINITIONS
        const transactionSheets = tableDefinitions.tableNames
            .filter(tableName => {
                const tableDef = tableDefinitions.getByName(tableName);
                return tableDef.type === TABLE_TYPES.TRANSACTION_DATA;
            });

        let clearedCount = 0;
        let totalRowsCleared = 0;

        for (const sheetName of transactionSheets) {
            const rowsCleared = this.cleanupSheet(sheetName);
            if (rowsCleared > 0) {
                clearedCount++;
                totalRowsCleared += rowsCleared;
            }
        }

        const message = `Cleanup completed! Cleared ${totalRowsCleared} total rows from ${clearedCount} transaction data sheets. Master data preserved.`;
        Logger.log(message);

        return message;
    },

    /**
     * Cleanup log data sheets only
     * Dynamically identifies and clears log data sheets from TABLE_DEFINITIONS
     * Keeps master data and transaction data sheets intact
     * @returns {string} Summary message of the cleanup operation
     */
    cleanupLogDataSheets() {
        // Dynamically get log sheets from TABLE_DEFINITIONS
        const logSheets = tableDefinitions.tableNames
            .filter(tableName => {
                const tableDef = tableDefinitions.getByName(tableName);
                return tableDef.type === TABLE_TYPES.LOG;
            });

        let clearedCount = 0;
        let totalRowsCleared = 0;

        for (const sheetName of logSheets) {
            const rowsCleared = this.cleanupSheet(sheetName);
            if (rowsCleared > 0) {
                clearedCount++;
                totalRowsCleared += rowsCleared;
            }
        }

        const message = `Cleanup completed! Cleared ${totalRowsCleared} total rows from ${clearedCount} log data sheets. Master and transaction data preserved.`;
        Logger.log(message);

        return message;
    },

    cleanupAllDataSheets() {
        let clearedCount = 0;
        let totalRowsCleared = 0;

        for (const sheetName of tableDefinitions.tableNames) {
            const rowsCleared = this.cleanupSheet(sheetName);
            if (rowsCleared > 0) {
                clearedCount++;
                totalRowsCleared += rowsCleared;
            }
        }

        const message = `Cleanup completed! Cleared ${totalRowsCleared} total rows from ${clearedCount} data sheets. All data preserved.`;
        Logger.log(message);

        return message;
    }

};

