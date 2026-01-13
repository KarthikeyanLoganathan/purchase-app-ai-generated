const setup = {
    SHEET_NAMES: Object.freeze({
        STATISTICS: "statistics",
        CONFIG: "config",
        CONTROL: "control",
    }),
    /**
     * Setup a all Data Worksheets according to schema
     */
    setupDataTableSheets() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        // Setup all tables
        for (const tableName of tableDefinitions.tableNames) {
            this.setupDataTableSheet(tableName, true);
        }

        Logger.log("SetupDataTableSheets completed successfully!");
        Logger.log("⚠️  IMPORTANT: Go to config sheet and change APP_CODE value!");
        return true;
    },

    deleteDefaultSheetIfEmpty() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        // Delete default "Sheet1" if it exists and is empty
        const sheet1 = ss.getSheetByName("Sheet1");
        if (sheet1 && sheet1.getLastRow() === 0) {
            ss.deleteSheet(sheet1);
        }
    },

    setupControlSheet() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const execContext = utils.getExecutionContext();
        let isNewSheet = false;
        let sheet = ss.getSheetByName(this.SHEET_NAMES.CONTROL);
        if (!sheet) {
            sheet = ss.insertSheet(this.SHEET_NAMES.CONTROL);
            isNewSheet = true;
        }
        sheet.getRange(1, 1, 2, 2)
            .setValues([
                ["Default Currency", "=XLOOKUP(TRUE,currencies!E:E,currencies!A:A)"],
                ["Default Unit of Measure", "=XLOOKUP(TRUE,unit_of_measures!D:D,unit_of_measures!A:A)"],
            ]);

        if (!isNewSheet) {
            const existingNamedRanges = ss.getNamedRanges();
            for (let i = 0; i < existingNamedRanges.length; i++) {
                const enr = existingNamedRanges[i];
                if (enr.getName() === 'DEFAULT_CURRENCY') {
                    enr.remove();
                } else if (enr.getName() === 'DEFAULT_UNIT_OF_MEASURE') {
                    enr.remove();
                }
            }
        }

        ss.setNamedRange('DEFAULT_CURRENCY', sheet.getRange('B1'));
        ss.setNamedRange('DEFAULT_UNIT_OF_MEASURE', sheet.getRange('B2'));

        Logger.log("Control sheet created/changed");
    },

    setupConfigSheet() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = utils.getExecutionContext();
        let configSheet = ss.getSheetByName(this.SHEET_NAMES.CONFIG);
        if (!configSheet) {
            configSheet = ss.insertSheet(this.SHEET_NAMES.CONFIG);
        }
        configSheet
            .getRange(1, 1, 1, 3)
            .setValues([["name", "value", "description"]]);

        // Format header
        configSheet
            .getRange(1, 1, 1, 3)
            .setBackground("#FF6B6B")
            .setFontColor("#FFFFFF")
            .setFontWeight("bold")
            .setHorizontalAlignment("center");
        if (sheet.isSheetsUI) {
            configSheet.autoResizeColumn(1);
            configSheet.autoResizeColumn(2);
            configSheet.autoResizeColumn(3);
        }
        configSheet.setFrozenRows(1);

        if (!config.getConfigValue("APP_CODE")) {
            config.setConfigValue("APP_CODE", "CHANGE_ME_" + new Date().getTime());
        }
        Logger.log("Config sheet created/changed. IMPORTANT: Change APP_CODE value!");
    },

    /**
     * Setup a single table/sheet
     * @param {string} tableName - Name of the table to setup
     */
    setupDataTableSheet(tableName, doLogging = true) {
        const execContext = utils.getExecutionContext();
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const tableDef = tableDefinitions.getByName(tableName);
        if (!tableDef) {
            throw new Error(`Table "${tableName}" not found in TABLE_DEFINITIONS`);
        }

        let sheet = ss.getSheetByName(tableName);

        if (sheet) {
            if (doLogging) {
                Logger.log(`Sheet "${tableName}" already exists. Checking columns...`);
            }

            const currentMaxColumn = sheet.getMaxColumns();
            const requiredColumnNames = tableDef.columnNames;
            const requiredColumns = requiredColumnNames.length;

            // Read current header row
            let currentHeaders = [];
            if (currentMaxColumn > 0) {
                currentHeaders = sheet.getRange(1, 1, 1, currentMaxColumn).getValues()[0];
            }

            // Process each required column position
            for (let targetIndex = 0; targetIndex < requiredColumns; targetIndex++) {
                const requiredColumnName = requiredColumnNames[targetIndex];
                const currentColumnName = currentHeaders[targetIndex];

                if (currentColumnName === requiredColumnName) {
                    // Column is already in the correct position
                    continue;
                }

                // Find if the required column exists elsewhere
                const existingIndex = currentHeaders.indexOf(requiredColumnName);

                if (existingIndex !== -1 && existingIndex > targetIndex) {
                    // Column exists but at wrong position - move it
                    if (doLogging) {
                        Logger.log(
                            `Moving column "${requiredColumnName}" from position ${existingIndex + 1} to ${targetIndex + 1} in "${tableName}"`
                        );
                    }

                    // Move the column by inserting at target position and copying data
                    sheet.insertColumnBefore(targetIndex + 1);

                    // Copy data from old position to new position (existingIndex is now +1 due to insert)
                    const maxRows = sheet.getMaxRows();
                    if (maxRows > 0) {
                        const sourceRange = sheet.getRange(1, existingIndex + 2, maxRows, 1);
                        const targetRange = sheet.getRange(1, targetIndex + 1, maxRows, 1);
                        sourceRange.copyTo(targetRange);
                    }

                    // Delete the old column (now at existingIndex + 2)
                    sheet.deleteColumn(existingIndex + 2);

                    // Update our tracking array
                    currentHeaders.splice(existingIndex, 1);
                    currentHeaders.splice(targetIndex, 0, requiredColumnName);

                } else if (existingIndex === -1) {
                    // Column doesn't exist - insert new column
                    if (doLogging) {
                        Logger.log(
                            `Inserting new column "${requiredColumnName}" at position ${targetIndex + 1} in "${tableName}"`
                        );
                    }

                    if (targetIndex < currentHeaders.length) {
                        sheet.insertColumnBefore(targetIndex + 1);
                    } else {
                        sheet.insertColumnAfter(currentHeaders.length);
                    }

                    // Set the header
                    sheet.getRange(1, targetIndex + 1).setValue(requiredColumnName);

                    // Update our tracking array
                    currentHeaders.splice(targetIndex, 0, requiredColumnName);
                }
            }

            // Delete any columns with unwanted or empty headers
            const finalMaxColumn = sheet.getMaxColumns();
            /**  @type {Array<string>}  */
            const allAllowedColumns = [...requiredColumnNames, ...tableDef.lookupColumnNames];
            for (let colIndex = finalMaxColumn; colIndex >= 1; colIndex--) {
                const headerValue = sheet.getRange(1, colIndex).getValue();
                const headerStr = String(headerValue).trim();

                // Delete if header is empty or not in required columns list (including lookup columns)
                if (!headerStr || !allAllowedColumns.includes(headerStr)) {
                    sheet.deleteColumn(colIndex);
                    if (doLogging) {
                        Logger.log(
                            `Deleted column ${colIndex} with ${!headerStr ? 'empty' : 'unwanted'} header "${headerStr}" from "${tableName}"`
                        );
                    }
                }
            }

            // Ensure header row has correct values (in case any got lost)
            sheet.getRange(1, 1, 1, requiredColumns).setValues([[...requiredColumnNames]]);

            // Format header
            sheet
                .getRange(1, 1, 1, tableDef.columnNames.length)
                .setBackground("#4285F4")
                .setFontColor("#FFFFFF")
                .setFontWeight("bold")
                .setHorizontalAlignment("center");

            // Apply lookup formulas if defined
            this.applyLookupFormulas(sheet, tableName);

            // Apply numeric formatting to existing data
            this.applyNumericFormatting(sheet, tableName);

            if (execContext.isSheetsUI) {
                // Optimize column widths
                utils.autoResizeSheetColumns(sheet);
            }
            if (doLogging) {
                Logger.log(`Sheet "${tableName}" updated successfully`);
            }
        } else {
            // Create new sheet
            sheet = ss.insertSheet(tableName);

            // Set header row
            sheet.getRange(1, 1, 1, tableDef.columnNames.length).setValues([[...tableDef.columnNames]]);

            // Format header
            sheet
                .getRange(1, 1, 1, tableDef.columnNames.length)
                .setBackground("#4285F4")
                .setFontColor("#FFFFFF")
                .setFontWeight("bold")
                .setHorizontalAlignment("center");

            // Freeze header row
            sheet.setFrozenRows(1);

            // Delete extra rows (Google Sheets creates 1000 rows by default)
            // Keep only header row + 1 empty data row
            const maxRows = sheet.getMaxRows();
            if (maxRows > 2) {
                sheet.deleteRows(3, maxRows - 2);
            }

            // Delete extra columns beyond what we need
            const maxColumns = sheet.getMaxColumns();
            const totalInitialCols = tableDef.totalColumnCount;

            if (maxColumns > totalInitialCols) {
                sheet.deleteColumns(
                    totalInitialCols + 1,
                    maxColumns - totalInitialCols
                );
            }

            // Apply lookup formulas if defined
            this.applyLookupFormulas(sheet, tableName);

            // Apply numeric formatting (even on empty sheets for when data is added)
            this.applyNumericFormatting(sheet, tableName);

            if (execContext.isSheetsUI) {
                // Optimize column widths
                utils.autoResizeSheetColumns(sheet);
            }
            if (doLogging) {
                Logger.log(`Sheet "${tableName}" created successfully`);
            }
        }
    },

    /**
     * Apply number formatting and alignment to numeric columns
     */
    applyNumericFormatting(sheet, tableName) {
        const tableDef = tableDefinitions.getByName(tableName);
        if (!tableDef?.columnCount) return;

        const lastRow = sheet.getLastRow();
        if (lastRow < 2) return; // No data rows to format

        for (let i = 0; i < tableDef.columnNames.length; i++) {
            const columnName = tableDef.columnNames[i];
            const columnType = tableDef.getColumnType(columnName);
            const colIndex = i + 1;
            // Apply to data rows (row 2 onwards)
            const range = sheet.getRange(2, colIndex, lastRow - 1, 1);
            if (columnType === DATA_TYPES.ID || columnType === DATA_TYPES.INTEGER) {
                range.setNumberFormat("0");
                range.setHorizontalAlignment("right");
            } else if (columnType === DATA_TYPES.QUANTITY) {
                range.setNumberFormat("0.00");
                range.setHorizontalAlignment("right");
            } else if (columnType === DATA_TYPES.AMOUNT ||
                columnType === DATA_TYPES.DOUBLE) {
                range.setNumberFormat("#,##0.00");
                range.setHorizontalAlignment("right");
            } else if (columnType === DATA_TYPES.PERCENT) {
                range.setNumberFormat("0.00");
                range.setHorizontalAlignment("right");
            } else if (columnType === DATA_TYPES.BOOLEAN) {
                range.setNumberFormat("0");
                range.setHorizontalAlignment("center");
            } else if (columnType === DATA_TYPES.TIME_STAMP) {
                range.setNumberFormat("dd/mm/yyyy hh:mm:ss");
            }
        }
    },

    /**
     * Get column index mapping from sheet headers
     * This makes the code resilient to column reordering in sheets
     * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet - The sheet to read headers from
     * @param {string} tableName - The table name (optional, for validation)
     * @returns {Object.<string, number>} Map of column name to column index (0-based)
     */
    getSheetColumnMap(sheet, tableName) {
        /** @type {Object.<string, number>} */
        const columnMap = {};
        if (!sheet) {
            throw new Error('Sheet is required');
        }

        const lastCol = sheet.getLastColumn();
        if (lastCol === 0) {
            return columnMap;
        }

        // Read first row as headers
        const headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0];

        // Create column map
        headers.forEach((header, index) => {
            if (header && header.toString().trim() !== '') {
                columnMap[header.toString().trim()] = index;
            }
        });

        // Optionally validate against TABLE_DEFINITIONS
        const tableDef = tableDefinitions.getByName(tableName);
        if (tableName && tableDef) {
            const expectedColumns = tableDef.columnNames
            const missingColumns = expectedColumns.filter(col => !(col in columnMap));
            if (missingColumns.length > 0) {
                console.log(`Sheet "${sheet.getName()}" is missing expected columns: ${missingColumns.join(', ')}`);
            }
        }

        return columnMap;
    },

    setupDataTableSheetForCurrentSheet() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getActiveSheet();
        const tableName = sheet.getName();

        this.setupDataTableSheet(tableName, true);
    },

    /**
     * Setup statistics sheet showing row counts for all data tables
     */
    setupStatisticsSheet() {
        const execContext = utils.getExecutionContext();
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        let statsSheet = ss.getSheetByName(this.SHEET_NAMES.STATISTICS);

        // Create sheet if it doesn't exist
        if (!statsSheet) {
            statsSheet = ss.insertSheet(this.SHEET_NAMES.STATISTICS);
            Logger.log(`Sheet "${this.SHEET_NAMES.STATISTICS}" created`);
        } else {
            Logger.log(`Sheet "${this.SHEET_NAMES.STATISTICS}" already exists. Updating...`);
        }

        // Clear existing content
        statsSheet.clear();
        const statisticsSheetMaxColumns = 5;
        let callTablesOKFormula = `=IFERROR(COUNTIF(C2:C${tableDefinitions.tableNames.length + 1},TRUE) = ${tableDefinitions.tableNames.length},FALSE)`;

        // Set header row
        const headers = [["Sheet", "Records", "Column Def OK?", "All Tables OK ->", callTablesOKFormula]];
        statsSheet.getRange(1, 1, 1, statisticsSheetMaxColumns).setValues(headers);

        // Format header
        statsSheet.getRange(1, 1, 1, statisticsSheetMaxColumns)
            .setBackground("#4CAF50")
            .setFontColor("#FFFFFF")
            .setFontWeight("bold")
            .setHorizontalAlignment("center");

        // Freeze header row
        statsSheet.setFrozenRows(1);

        // Get all table names from tableDefinitions
        const tableNames = tableDefinitions.tableNames;
        const numTables = tableNames.length;

        // Prepare data rows with formulas
        const dataRows = tableNames.map(tableName => {
            // Formula to count non-empty rows in column A (excluding header)
            // COUNTA counts all non-empty cells in the first column, then subtract 1 for the header
            const formulaCountRows = `=MAX(0, COUNTA(INDIRECT("${tableName}!A:A")) - 1)`;
            const tableDef = tableDefinitions.getByName(tableName);
            const requiredColumns = "{" + [
                ...tableDef.columnNames,
                ...tableDef.lookupColumnNames
            ].map(col => "\"" + col.trim() + "\"").join(",") + "}";
            //Comma separator for horizontal array
            //=ARRAYFORMULA(AND(A5:A6={"name";"value"}))
            const colLetterStart = utils.columnIndexToLetter(0);
            const colLetterEnd = utils.columnIndexToLetter(tableDef.totalColumnCount - 1);
            const formulaCheckColumns = `=IFERROR(ARRAYFORMULA(AND(${requiredColumns} = INDIRECT("${tableName}!${colLetterStart}1:${colLetterEnd}1"))), FALSE)`;

            return [tableName, formulaCountRows, formulaCheckColumns];
        });

        // Write data rows
        if (numTables > 0) {
            statsSheet.getRange(2, 1, numTables, 3).setValues(dataRows);
        }

        if (execContext.isSheetsUI) {
            // Auto-resize columns
            statsSheet.autoResizeColumn(1);
            statsSheet.autoResizeColumn(2);
            statsSheet.autoResizeColumn(3);
        }

        // Set column alignment
        if (numTables > 0) {
            statsSheet.getRange(2, 1, numTables, 1).setHorizontalAlignment("left");
            statsSheet.getRange(2, 2, numTables, 1).setHorizontalAlignment("right");
            statsSheet.getRange(2, 3, numTables, 1).setHorizontalAlignment("center");
        }

        // Delete extra rows (keep header + data rows + 1 empty)
        const maxRows = statsSheet.getMaxRows();
        const neededRows = numTables + 1;
        if (maxRows > neededRows) {
            statsSheet.deleteRows(neededRows + 1, maxRows - neededRows);
        }

        // Delete extra columns beyond what we need (2 columns)
        const maxColumns = statsSheet.getMaxColumns();
        if (maxColumns > statisticsSheetMaxColumns) {
            statsSheet.deleteColumns(statisticsSheetMaxColumns + 1, maxColumns - statisticsSheetMaxColumns);
        }

        Logger.log(`Statistics sheet setup completed with ${numTables} tables`);
        return `Statistics sheet ready with ${numTables} tables tracked`;
    },

    /**
     * Apply lookup formulas to a sheet for computed/reference columns
     * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet - The sheet to apply lookup formulas to
     * @param {string} tableName - The name of the table/sheet
     * @returns {void}
     */
    applyLookupFormulas(sheet, tableName) {
        //Generates formulas like 
        //=ARRAYFORMULA({"manufacturer_name"; IF(B2:B="", "", IFERROR(INDEX(manufacturers!C:C, MATCH(B2:B, manufacturers!A:A, 0)), "Not Found"))})
        //Old approach        
        //=ARRAYFORMULA({"manufacturer_name"; IF(B2:B="", "", IFERROR(VLOOKUP(B2:B, manufacturers!A:C, 3, FALSE), "Not Found"))})
        const tableDef = tableDefinitions.getByName(tableName);
        if (!tableDef.lookupColumnCount) return;
        let currentLookupIndex = 0;

        // Iterate through each source column and its lookup columns
        for (const lookupColumnName of tableDef.lookupColumnNames) {
            const lookupColumnDef = tableDef.getLookupColumnDefinition(lookupColumnName);
            const sourceColumnIndex = tableDef.columnIndices[lookupColumnDef.sourceForeignKeyColumn];
            if (sourceColumnIndex === undefined) {
                Logger.log(`Warning: Column '${lookupColumnDef.sourceForeignKeyColumn}' not found in sheet '${tableName}'`);
                continue;
            }
            // Get the target table from FOREIGN_KEY_RELATIONSHIPS
            const foreignKeyRelation = tableDef.getForeignKeyRelation(lookupColumnDef.sourceForeignKeyColumn);
            if (!foreignKeyRelation) {
                Logger.log(`Warning: Foreign Key Relation for field '${lookupColumnDef.sourceForeignKeyColumn}' is not found in sheet '${tableName}'`);
                continue;
            }
            const targetTableDef = tableDefinitions.getByName(foreignKeyRelation.table);
            if (!targetTableDef) {
                Logger.log(`Warning: Foreign Key Table '${foreignKeyRelation.table}' for field '${tableName}.${lookupColumnDef.sourceForeignKeyColumn}' is not found`);
                continue;
            }
            // Column letter for the source column - now supports columns beyond Z (AA, AB, etc.)
            const sourceColLetter = utils.columnIndexToLetter(sourceColumnIndex);
            const sourceRange = `${sourceColLetter}2:${sourceColLetter}`;
            let matchTheKeyColumnIndex = targetTableDef.columnIndices[foreignKeyRelation.column];
            let matchTheKeyColumnLetter = utils.columnIndexToLetter(matchTheKeyColumnIndex);
            let matchTheKeyRange = `${foreignKeyRelation.table}!${matchTheKeyColumnLetter}:${matchTheKeyColumnLetter}`;
            let matchTheKeyFormula = `MATCH(${sourceRange}, ${matchTheKeyRange}, 0)`;
            // Apply formula for each lookup column
            let resultColumnName = lookupColumnDef.targetColumn;
            const lookupColIndex = tableDef.columnCount + currentLookupIndex + 1;
            const headerRange = sheet.getRange(1, lookupColIndex);
            // Find the target column index in the target table
            // Check if it's a regular column first
            let resultColumnIndex = targetTableDef.columnIndices[resultColumnName];
            // If not found in regular columns, check if it's a lookup column in the target table
            if (resultColumnIndex === undefined) {
                // Find the position among lookup columns
                const lookupIndex = targetTableDef.lookupColumnNames.indexOf(resultColumnName);
                if (lookupIndex !== -1) {
                    // Lookup columns come after regular columns
                    resultColumnIndex = targetTableDef.columnCount + lookupIndex;
                }
            }
            if (resultColumnIndex === undefined) {
                Logger.log(`Warning: Column '${resultColumnName}' not found in sheet '${foreignKeyRelation.table}'`);
                currentLookupIndex++;
                continue;
            }
            let resultColLetter = utils.columnIndexToLetter(resultColumnIndex);
            let resultColumnRange = `${foreignKeyRelation.table}!${resultColLetter}:${resultColLetter}`;
            let resultIndexFormula = `IFERROR(INDEX(${resultColumnRange}, ${matchTheKeyFormula}), "Not Found")`;
            let arrayFomula = `=ARRAYFORMULA({"${lookupColumnName}"; IF(${sourceRange}="", "", ${resultIndexFormula})})`;
            // Set header name and formula
            headerRange.setFormula(arrayFomula);

            // Format header
            headerRange
                .setBackground("#673AB7") // Different color for lookup columns
                .setFontColor("#FFFFFF")
                .setFontWeight("bold")
                .setHorizontalAlignment("center");

            // Format data rows to indicate they are read-only
            const dataRange = sheet.getRange(2, lookupColIndex, sheet.getMaxRows() - 1, 1);
            dataRange.setFontColor("#B71C1C"); // Material Dark Red

            currentLookupIndex++;
        }
    },

    setupSheets() {
        this.setupConfigSheet();
        this.setupDataTableSheets();
        this.setupStatisticsSheet();
        this.setupControlSheet();
        this.deleteDefaultSheetIfEmpty();
        Logger.log(`Sheets were setup successfully`);
        return true;
    }
};