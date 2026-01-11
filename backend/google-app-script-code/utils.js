const utils = {
    getExecutionContext() {
        try {
            // Try to get UI - only works in interactive mode
            SpreadsheetApp.getUi();
            return {
                isWebApp: false,
                isSheetsUI: true,
                canShowToast: true,
                canShowAlert: true
            };
        } catch (e) {
            return {
                isWebApp: true,
                isSheetsUI: false,
                canShowToast: false,
                canShowAlert: false
            };
        }
    },

    roundToDigits(num, digits) {
        const multiplier = Math.pow(10, digits);
        return Math.round(num * multiplier) / multiplier;
    },

    UUID() {
        return Utilities.getUuid();
    },

    getEpochTimeMilliseconds(input, defaultValue) {
        let result = input;
        if (!result) {
            result = defaultValue ? defaultValue : new Date();
        }
        if (typeof result === "string") {
            result = new Date(result);
        }
        if (result instanceof Date) {
            result = result.getTime();
        }
        return result;
    },

    /**
     * Fill the current active cell with a UUID value
     */
    fillUUID() {
        const sheet = SpreadsheetApp.getActiveSheet();
        const cell = sheet.getActiveCell();
        const execContext = this.getExecutionContext();

        if (!cell) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("No cell selected!");
            }
            return;
        }

        cell.setValue(this.UUID());
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("UUID filled successfully!");
        }
    },

    removeProtectionsFromSheet(sheet) {
        // Remove all range-level protections
        const rangeProtections = sheet.getProtections(SpreadsheetApp.ProtectionType.RANGE);
        for (let i = 0; i < rangeProtections.length; i++) {
            rangeProtections[i].remove();
        }

        // Remove all sheet-level protections
        const sheetProtections = sheet.getProtections(SpreadsheetApp.ProtectionType.SHEET);
        for (let i = 0; i < sheetProtections.length; i++) {
            sheetProtections[i].remove();
        }
    },

    /**
     * Get the deployed web app URL
     */
    getWebAppUrl() {
        return ScriptApp.getService().getUrl();
    },

    /**
     * Helper function to automatically resize all columns in a sheet
     * Includes header rows in calculation and ensures a minimum width
     */
    autoResizeSheetColumns(sheet) {
        const lastColumn = sheet.getLastColumn();
        if (lastColumn === 0) return;

        // Force a flush to ensure all pending changes (like header text updates) are applied before resizing
        SpreadsheetApp.flush();

        const headers = sheet.getRange(1, 1, 1, lastColumn).getValues()[0];

        for (let i = 1; i <= lastColumn; i++) {
            const headerText = String(headers[i - 1] || "");

            sheet.autoResizeColumn(i);

            // Google Sheets autoResizeColumn sometimes ignores the header width when there's no data.
            // We'll calculate a minimum width based on the header text length.
            // Approximate 10 pixels per character for bold text, plus some padding
            const estimatedHeaderWidth = headerText.length * 10 + 20;

            const currentWidth = sheet.getColumnWidth(i);
            const finalWidth = Math.max(currentWidth, estimatedHeaderWidth, 100);

            sheet.setColumnWidth(i, finalWidth);
        }
    },

    /**
     * Convert a column index (0-based) to column letter notation (A, B, ..., Z, AA, AB, ...)
     * @param {number} columnIndex - 0-based column index
     * @returns {string} Column letter(s)
     */
    columnIndexToLetter(columnIndex) {
        let letter = '';
        let num = columnIndex;

        while (num >= 0) {
            letter = String.fromCharCode(65 + (num % 26)) + letter;
            num = Math.floor(num / 26) - 1;
        }

        return letter;
    },

    /**
     * @param {GoogleAppsScript.Spreadsheet.Range} targetRange
     * @param {string} sourceSheetName
     * @param {string} sourceColumnName
     * @param {number} startRow
     * @returns {void}
     */
    createDataValidationForGivenRange(targetRange, sourceSheetName, sourceColumnName, startRow) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(sourceSheetName);
        if (sheet) {
            const lastRow = sheet.getLastRow();
            if (lastRow > 1) {
                const colIndx = tableDefinitions.getByName(sourceSheetName)?.columnIndices?.[sourceColumnName];
                //TODO Warn if colIndx is undefined                
                if (colIndx !== undefined) {
                    const range = sheet.getRange(startRow, colIndx + 1, lastRow - startRow + 1, 1);
                    const rule = SpreadsheetApp.newDataValidation()
                        .requireValueInRange(range, true)
                        .setAllowInvalid(false)
                        .build();
                    targetRange.setDataValidation(rule);
                }
            }
        }
    },

    /**
     * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet
     * @param {number} startRow
     * @returns {number | undefined} Number of rows deleted, or undefined if none deleted
     */
    deleteRowsFromSheetGivenStartRow(sheet, startRow) {
        const numCols = sheet.getLastColumn();
        const maxRows = sheet.getMaxRows(); // Use getMaxRows() to include empty rows

        if (startRow > maxRows) {
            return; // Nothing to delete
        }

        // Calculate total number of rows including startRow to maxRows
        const numRows = maxRows - startRow + 1;

        // Clear content and formatting from startRow onwards (all rows)
        if (numCols > 0) {
            sheet.getRange(startRow, 1, numRows, numCols).clearContent().clearFormat();
        }

        // Delete all rows after startRow (keep startRow cleared but not deleted)
        if (numRows > 1) {
            sheet.deleteRows(startRow + 1, numRows - 1);
        }

        return numRows;
    },

    normalizeName(input) {
        if (!input) return '';

        // Remove punctuation (commas, periods, semicolons, etc.) but keep spaces and alphanumeric
        const cleaned = input.replace(/[^\w\s]/g, ' ');

        // Split into words, filter out empty strings
        const words = cleaned.split(/\s+/).filter(word => word.length > 0);

        // Capitalize first letter of each word, lowercase the rest
        const camelCased = words.map(word => {
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        });

        // Join with single space
        return camelCased.join(' ');

        // Examples:
        // console.log(normalizeName("1,Model box;"));     // "1 Model Box"
        // console.log(normalizeName("1 Model Box;"));     // "1 Model Box"
        // console.log(normalizeName("hello,world.test;")); // "Hello World Test"
        // console.log(normalizeName("ABC,def,GHI"));       // "Abc Def Ghi"        
    },

    /**
     * Normalize values in selected column(s) excluding the header row
     * Removes punctuation and applies proper camel casing
     */
    normalizeTextsInSelectedColumn() {
        const sheet = SpreadsheetApp.getActiveSheet();
        const selection = sheet.getActiveRange();
        const execContext = this.getExecutionContext();

        if (!selection) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a column or range to normalize!");
            }
            return;
        }

        const startRow = selection.getRow();
        const startCol = selection.getColumn();
        const numRows = selection.getNumRows();
        const numCols = selection.getNumColumns();

        // Determine if header row is included in selection
        const dataStartRow = (startRow === 1) ? 2 : startRow;
        const dataNumRows = (startRow === 1) ? numRows - 1 : numRows;

        if (dataNumRows <= 0) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("No data rows to normalize!");
            }
            return;
        }

        // Get the data range (excluding header if row 1 was selected)
        const dataRange = sheet.getRange(dataStartRow, startCol, dataNumRows, numCols);
        const values = dataRange.getValues();

        // Normalize each cell value
        const normalizedValues = values.map(row => {
            return row.map(cell => {
                if (typeof cell === 'string' && cell.trim() !== '') {
                    return this.normalizeName(cell);
                }
                return cell;
            });
        });

        // Write normalized values back
        dataRange.setValues(normalizedValues);

        const message = `Normalized ${dataNumRows} row(s) and ${numCols} column(s)`;
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast(message);
        }
    },

    /**
     * Build row data array from record object using column map
     * @param {Object} record - The record object with column name keys
     * @param {ReadonlyArray<string>} columnNames - Array of column names in desired order
     * @param {Object.<string, number>} columnMap - Map of column name to sheet column index
     * @param {string} tableName - The table name (for date column detection)
     * @returns {Array} Row data array aligned with sheet column order
     */
    buildRowDataFromRecord(record, columnNames, columnMap, tableName) {
        // Create an array with undefined values at actual sheet positions
        const maxIndex = Math.max(...Object.values(columnMap));
        const rowData = new Array(maxIndex + 1);

        // Fill in values based on column map
        columnNames.forEach((colName) => {
            const sheetIndex = columnMap[colName];
            if (sheetIndex !== undefined) {
                let val = record[colName] || "";

                // Handle date conversion
                if (val && tableDefinitions.getByName(tableName)?.isDateColumn(colName)) {
                    try {
                        const date = new Date(val);
                        if (!isNaN(date.getTime())) {
                            val = date;
                        }
                    } catch (e) {
                        // If parsing fails, use original value
                    }
                }

                rowData[sheetIndex] = val;
            }
        });

        return rowData;
    }
};