/**
 * Consistency Checks Module
 * 
 * This module handles foreign key consistency validation and cleanup.
 * It identifies and deletes records with invalid foreign key references.
 */

const consistencyChecks = {
    /**
     * Get record count statistics for all tables
     * Counts only records with non-null key values
     * @returns {Object} Statistics object with table names and record counts
     */
    getRecordCountStatistics() {
        Logger.log('\n' + '='.repeat(80));
        Logger.log('RECORD COUNT STATISTICS');
        Logger.log('='.repeat(80));

        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const statistics = {
            timestamp: new Date().toISOString(),
            tables: {},
            totalRecords: 0
        };

        for (const tableName of tableDefinitions.tableNames) {
            const sheet = ss.getSheetByName(tableName);

            if (!sheet) {
                Logger.log(`Warning: Sheet '${tableName}' not found`);
                statistics.tables[tableName] = {
                    count: 0,
                    status: 'not_found'
                };
                continue;
            }

            const lastRow = sheet.getLastRow();

            // Only header row or empty sheet
            if (lastRow <= 1) {
                statistics.tables[tableName] = {
                    count: 0,
                    status: 'empty'
                };
                Logger.log(`  ${tableName}: 0 records (empty)`);
                continue;
            }

            const tableDef = tableDefinitions.getByName(tableName);
            if (!tableDef) {
                Logger.log(`Warning: No metadata found for table '${tableName}'`);
                statistics.tables[tableName] = {
                    count: 0,
                    status: 'no_metadata'
                };
                continue;
            }

            const keyColumn = tableDef.keyColumn;
            const keyColumnIndex = tableDef.columnIndices[keyColumn];
            const keyData = sheet.getRange(2, keyColumnIndex + 1, lastRow - 1, 1).getValues();

            // Count non-null key values
            let count = 0;
            for (let i = 0; i < keyData.length; i++) {
                const keyValue = keyData[i][0];
                if (keyValue && keyValue !== '' && keyValue !== null && keyValue !== undefined) {
                    count++;
                }
            }

            statistics.tables[tableName] = {
                count: count,
                status: 'ok'
            };
            statistics.totalRecords += count;

            Logger.log(`  ${tableName}: ${count} records`);
        }

        Logger.log('-'.repeat(80));
        Logger.log(`Total records across all tables: ${statistics.totalRecords}`);
        Logger.log('='.repeat(80) + '\n');

        return statistics;
    },

    /**
     * Check for null or empty key values in a table
     * @param {string} tableName - Name of the table to check
     * @returns {Object} Results with rows that have null/empty key values
     */
    checkNullKeys(tableName) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);

        if (!sheet) {
            Logger.log(`Warning: Sheet '${tableName}' not found`);
            return { tableName, invalidRows: [], rowsToDelete: [] };
        }

        const lastRow = sheet.getLastRow();
        if (lastRow <= 1) {
            Logger.log(`Table '${tableName}' is empty (only header row)`);
            return { tableName, invalidRows: [], rowsToDelete: [] };
        }

        const tableDef = tableDefinitions.getByName(tableName);
        if (!tableDef) {
            Logger.log(`Warning: No metadata found for table '${tableName}'`);
            return { tableName, invalidRows: [], rowsToDelete: [] };
        }

        const keyColumn = tableDef.keyColumn;
        const keyColumnIndex = tableDef.columnIndices[keyColumn];
        const columnCount = tableDef.columnCount;

        // Get all data (key column and all columns to check if row is completely empty)
        const allData = sheet.getRange(2, 1, lastRow - 1, columnCount).getValues();

        const invalidRows = [];
        const rowsToDelete = [];

        for (let i = 0; i < allData.length; i++) {
            const row = allData[i];
            const keyValue = row[keyColumnIndex];
            const rowNumber = i + 2; // +2 because arrays are 0-indexed and we skip header

            // Check if entire row is empty (all cells are empty/null/undefined)
            const isRowCompletelyEmpty = row.every(cell =>
                cell === '' || cell === null || cell === undefined
            );

            // Skip completely empty rows (these are just blank rows in the sheet)
            if (isRowCompletelyEmpty) {
                continue;
            }

            // If row has data but key is missing, it's invalid
            if (!keyValue || keyValue === '' || keyValue === null || keyValue === undefined) {
                invalidRows.push({
                    rowNumber,
                    issue: `NULL or EMPTY ${keyColumn}`
                });
                rowsToDelete.push(rowNumber);
            }
        }

        Logger.log(`Found ${invalidRows.length} rows with null/empty ${keyColumn} in table '${tableName}'`);

        return {
            tableName,
            invalidRows,
            rowsToDelete
        };
    },

    /**
     * Check for duplicate key values in a table
     * @param {string} tableName - Name of the table to check
     * @returns {Object} Results with rows that have duplicate key values
     */
    checkDuplicateKeys(tableName) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);

        if (!sheet) {
            Logger.log(`Warning: Sheet '${tableName}' not found`);
            return { tableName, duplicates: [], rowsToDelete: [] };
        }

        const lastRow = sheet.getLastRow();
        if (lastRow <= 1) {
            Logger.log(`Table '${tableName}' is empty (only header row)`);
            return { tableName, duplicates: [], rowsToDelete: [] };
        }

        const tableDef = tableDefinitions.getByName(tableName);
        if (!tableDef) {
            Logger.log(`Warning: No metadata found for table '${tableName}'`);
            return { tableName, duplicates: [], rowsToDelete: [] };
        }

        const keyColumn = tableDef.keyColumn;
        const keyColumnIndex = tableDef.columnIndices[keyColumn];
        const keyData = sheet.getRange(2, keyColumnIndex + 1, lastRow - 1, 1).getValues();

        const keyMap = new Map(); // Map of key value -> [row numbers]
        const duplicates = [];
        const rowsToDelete = [];

        // Build map of key values to row numbers
        for (let i = 0; i < keyData.length; i++) {
            const keyValue = keyData[i][0];
            const rowNumber = i + 2;

            // Skip null/empty keys (handled by checkNullKeys)
            if (!keyValue || keyValue === '') {
                continue;
            }

            if (!keyMap.has(keyValue)) {
                keyMap.set(keyValue, []);
            }
            keyMap.get(keyValue).push(rowNumber);
        }

        // Find duplicates (keep first occurrence, mark rest for deletion)
        for (const [keyValue, rowNumbers] of keyMap.entries()) {
            if (rowNumbers.length > 1) {
                // Keep the first occurrence, delete the rest
                const duplicateRows = rowNumbers.slice(1); // All except the first
                duplicates.push({
                    keyValue,
                    firstRow: rowNumbers[0],
                    duplicateRows,
                    count: rowNumbers.length
                });
                rowsToDelete.push(...duplicateRows);
            }
        }

        Logger.log(`Found ${duplicates.length} duplicate ${keyColumn} values in table '${tableName}' (${rowsToDelete.length} rows to delete)`);

        return {
            tableName,
            duplicates,
            rowsToDelete
        };
    },

    /**
     * Load all key values from a target table into a Set for fast lookup
     * @param {string} tableName - Name of the table to load key values from
     * @returns {Set<string>} Set of all key values in the table
     */
    loadTargetKeys(tableName) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);

        if (!sheet) {
            Logger.log(`Warning: Sheet '${tableName}' not found`);
            return new Set();
        }

        const lastRow = sheet.getLastRow();
        if (lastRow <= 1) {
            // Only header row or empty sheet
            return new Set();
        }

        const tableDef = tableDefinitions.getByName(tableName);
        const keyColumn = tableDef.keyColumn;
        const keyColumnIndex = tableDef.columnIndices[keyColumn];
        const keyData = sheet.getRange(2, keyColumnIndex + 1, lastRow - 1, 1).getValues();

        const keySet = new Set();
        for (let i = 0; i < keyData.length; i++) {
            const keyValue = keyData[i][0];
            if (keyValue && keyValue !== '') {
                keySet.add(keyValue);
            }
        }

        Logger.log(`Loaded ${keySet.size} key values from table '${tableName}'`);
        return keySet;
    },

    /**
     * Check a single table for foreign key violations
     * @param {string} tableName - Name of the child table to check
     * @returns {Object} Results object with invalid records and deletion info
     */
    checkTableConsistency(tableName) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);

        if (!sheet) {
            Logger.log(`Warning: Sheet '${tableName}' not found`);
            return { tableName, invalidRecords: [], deleted: 0 };
        }

        const tableDef = tableDefinitions.getByName(tableName);
        if (tableDef.foreignKeyColumnNames.length === 0) {
            Logger.log(`No foreign key relationships defined for table '${tableName}'`);
            return { tableName, invalidRecords: [], deleted: 0 };
        }

        Logger.log(`Checking consistency for table '${tableName}'...`);

        // Load all target key values into Sets for fast lookup
        const targetKeySets = {};
        for (const columnName of tableDef.foreignKeyColumnNames) {
            const relation = tableDef.getForeignKeyRelation(columnName)
            if (!targetKeySets[relation.table]) {
                targetKeySets[relation.table] = this.loadTargetKeys(relation.table);
            }
        }

        // Get all data from the child table
        const lastRow = sheet.getLastRow();
        if (lastRow <= 1) {
            Logger.log(`Table '${tableName}' is empty (only header row)`);
            return { tableName, invalidRecords: [], deleted: 0 };
        }

        const lastCol = tableDef.columnCount;
        const data = sheet.getRange(2, 1, lastRow - 1, lastCol).getValues();

        // Track rows to delete (in reverse order for safe deletion)
        const rowsToDelete = [];
        const invalidRecords = [];

        // Check each row for foreign key violations
        for (let i = 0; i < data.length; i++) {
            const row = data[i];
            const rowNumber = i + 2; // +2 because arrays are 0-indexed and we skip header
            let hasViolation = false;
            const violations = [];

            for (const columnName of tableDef.foreignKeyColumnNames) {
                const relation = tableDef.getForeignKeyRelation(columnName)
                //relation.table, relation.column
                const fkColumnIndex = tableDef.columnIndices[columnName];
                const foreignKeyValue = row[fkColumnIndex];

                // Skip null/empty foreign keys (these might be optional)
                if (!foreignKeyValue || foreignKeyValue === '') {
                    continue;
                }

                // Check if the foreign key exists in the target table
                const targetKeySet = targetKeySets[relation.table];
                if (!targetKeySet.has(foreignKeyValue)) {
                    hasViolation = true;
                    violations.push({
                        column: columnName,
                        value: foreignKeyValue,
                        targetTable: relation.table
                    });
                }
            }

            if (hasViolation) {
                const keyColumn = tableDef.keyColumn;
                const keyColumnIndex = tableDef.columnIndices[keyColumn];
                const recordKey = row[keyColumnIndex];

                invalidRecords.push({
                    rowNumber,
                    keyColumn,
                    key: recordKey,
                    violations
                });
                rowsToDelete.push(rowNumber);
            }
        }

        Logger.log(`Found ${invalidRecords.length} invalid records in table '${tableName}'`);

        return {
            tableName,
            invalidRecords,
            rowsToDelete
        };
    },

    /**
     * Delete invalid records from a table
     * @param {string} tableName - Name of the table
     * @param {Array<number>} rowsToDelete - Array of row numbers to delete
     * @returns {number} Number of rows deleted
     */
    deleteInvalidRecords(tableName, rowsToDelete) {
        if (!rowsToDelete || rowsToDelete.length === 0) {
            return 0;
        }

        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(tableName);

        if (!sheet) {
            Logger.log(`Warning: Sheet '${tableName}' not found`);
            return 0;
        }

        // Sort rows in descending order to delete from bottom to top
        // This prevents row number shifts during deletion
        rowsToDelete.sort((a, b) => b - a);

        Logger.log(`Deleting ${rowsToDelete.length} invalid records from table '${tableName}'...`);

        for (const rowNumber of rowsToDelete) {
            sheet.deleteRow(rowNumber);
        }

        Logger.log(`Successfully deleted ${rowsToDelete.length} records from table '${tableName}'`);
        return rowsToDelete.length;
    },

    /**
     * Log changes to the change log after deleting records
     * @param {string} tableName - Name of the table
     * @param {Array<Object>} invalidRecords - Array of invalid records with key values
     */
    logDeletions(tableName, invalidRecords) {
        if (!invalidRecords || invalidRecords.length === 0) {
            return;
        }

        const keys = invalidRecords.map(record => record.key).filter(key => key);

        if (keys.length > 0 && typeof changeLog !== 'undefined' && changeLog.logChanges) {
            const updatedAt = new Date();
            changeLog.logChanges(tableName, keys, CHANGE_MODE_DELETE, updatedAt);
            Logger.log(`Logged ${keys.length} deletions to change log for table '${tableName}'`);
        }
    },

    /**
     * Check key integrity for a table (null/empty and duplicates)
     * @param {string} tableName - Name of the table to check
     * @param {boolean} simulate - If true, only report. If false, delete invalid rows
     * @returns {Object} Results with key validation issues
     */
    checkKeyIntegrity(tableName, simulate = false) {
        const keyColumn = tableDefinitions.getByName(tableName).keyColumn;
        Logger.log(`\nChecking ${keyColumn} integrity for '${tableName}'...`);

        const nullCheck = this.checkNullKeys(tableName);
        const duplicateCheck = this.checkDuplicateKeys(tableName);

        const totalIssues = nullCheck.invalidRows.length + duplicateCheck.duplicates.length;
        const totalRowsToDelete = [...new Set([...nullCheck.rowsToDelete, ...duplicateCheck.rowsToDelete])];

        if (totalIssues > 0) {
            Logger.log(`  ⚠ ${keyColumn} integrity issues in '${tableName}':`);

            if (nullCheck.invalidRows.length > 0) {
                Logger.log(`    • ${nullCheck.invalidRows.length} rows with NULL/EMPTY ${keyColumn}`);
                if (nullCheck.invalidRows.length <= 10) {
                    for (const row of nullCheck.invalidRows) {
                        Logger.log(`      - Row ${row.rowNumber}: ${row.issue}`);
                    }
                }
            }

            if (duplicateCheck.duplicates.length > 0) {
                Logger.log(`    • ${duplicateCheck.duplicates.length} duplicate ${keyColumn} values (${duplicateCheck.rowsToDelete.length} duplicate rows)`);
                if (duplicateCheck.duplicates.length <= 10) {
                    for (const dup of duplicateCheck.duplicates) {
                        Logger.log(`      - ${keyColumn} '${dup.keyValue}': appears ${dup.count} times (keeping row ${dup.firstRow}, would delete rows ${dup.duplicateRows.join(', ')})`);
                    }
                }
            }

            if (simulate) {
                Logger.log(`  📊 SIMULATION: Would delete ${totalRowsToDelete.length} rows with ${keyColumn} issues`);
            } else {
                const deletedCount = this.deleteInvalidRecords(tableName, totalRowsToDelete);
                Logger.log(`  ✓ CLEANUP: Deleted ${deletedCount} rows with ${keyColumn} issues`);
            }
        } else {
            Logger.log(`  ✓ ${keyColumn} integrity OK in '${tableName}'`);
        }

        return {
            tableName,
            keyColumn,
            nullKeys: nullCheck.invalidRows.length,
            duplicateKeys: duplicateCheck.duplicates.length,
            duplicateRows: duplicateCheck.rowsToDelete.length,
            totalIssues,
            rowsToDelete: totalRowsToDelete,
            deleted: simulate ? 0 : totalRowsToDelete.length,
            wouldDelete: simulate ? totalRowsToDelete.length : 0
        };
    },

    /**
     * Check and clean a specific table
     * @param {string} tableName - Name of the table to check and clean
     * @param {boolean} simulate - If true, only simulate and report (don't delete). If false, perform cleanup (default: false)
     * @returns {Object} Results object with summary
     */
    checkAndCleanTable(tableName, simulate = false) {
        Logger.log(`\n${'='.repeat(60)}`);
        Logger.log(`Checking table: ${tableName}`);
        Logger.log('='.repeat(60));

        const result = this.checkTableConsistency(tableName);

        if (result.invalidRecords.length > 0) {
            Logger.log(`\n⚠ Invalid records found in '${tableName}': ${result.invalidRecords.length}`);

            // Group violations by type for better reporting
            const violationsByType = {};
            for (const record of result.invalidRecords) {
                for (const violation of record.violations) {
                    const key = `${violation.column} -> ${violation.targetTable}`;
                    if (!violationsByType[key]) {
                        violationsByType[key] = 0;
                    }
                    violationsByType[key]++;
                }
            }

            Logger.log(`\n  Violation breakdown:`);
            for (const [violationType, count] of Object.entries(violationsByType)) {
                Logger.log(`    • ${violationType}: ${count} invalid references`);
            }

            // Show detailed records only if count is manageable
            if (result.invalidRecords.length <= 20) {
                Logger.log(`\n  Detailed invalid records:`);
                for (const record of result.invalidRecords) {
                    Logger.log(`    Row ${record.rowNumber} (${record.keyColumn}: ${record.key}):`);
                    for (const violation of record.violations) {
                        Logger.log(`      - ${violation.column}: '${violation.value}' not found in ${violation.targetTable}`);
                    }
                }
            } else {
                Logger.log(`\n  (${result.invalidRecords.length} records - too many to list individually)`);
            }

            if (simulate) {
                result.deleted = 0;
                result.wouldDelete = result.invalidRecords.length;
                Logger.log(`\n  📊 SIMULATION: ${result.invalidRecords.length} records would be deleted`);
            } else {
                const deletedCount = this.deleteInvalidRecords(tableName, result.rowsToDelete);
                this.logDeletions(tableName, result.invalidRecords);
                result.deleted = deletedCount;
                result.wouldDelete = 0;
                Logger.log(`\n  ✓ CLEANUP: Deleted ${deletedCount} invalid records`);
            }
        } else {
            Logger.log(`✓ No consistency issues found in '${tableName}'`);
            result.deleted = 0;
            result.wouldDelete = 0;
        }

        return result;
    },

    /**
     * Check and clean all tables with foreign key relationships
     * @param {boolean} simulate - If true, only simulate and report (don't delete). If false, perform cleanup (default: true for safety)
     * @returns {Object} Summary of all checks and cleanups
     */
    checkAndCleanAllTables(simulate = true) {
        const mode = simulate ? 'SIMULATION MODE' : 'CLEANUP MODE';
        Logger.log('\n' + '='.repeat(80));
        Logger.log('COMPREHENSIVE CONSISTENCY CHECK - ' + mode);
        Logger.log('='.repeat(80));
        Logger.log(`Mode: ${simulate ? '📊 SIMULATION (no deletions)' : '🗑️  CLEANUP (will delete invalid records)'}`);
        Logger.log(`Timestamp: ${new Date().toISOString()}\n`);

        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const execContext = utils.getExecutionContext();

        if (execContext.canShowToast) {
            ss.toast(`Starting consistency check (${simulate ? 'simulation' : 'cleanup'})...`, 'Consistency Check', 5);
        }

        // Get all tables that need key validation
        const allTables = tableDefinitions.tableNames.filter(tableName => {
            const tableDef = tableDefinitions.getByName(tableName);
            return tableDef.type !== TABLE_TYPES.LOG;
        });

        // Step 1: Check key integrity across ALL tables first
        Logger.log('\n' + '-'.repeat(80));
        Logger.log('STEP 1: KEY INTEGRITY VALIDATION');
        Logger.log('-'.repeat(80));

        const keyResults = [];
        let totalKeyIssues = 0;
        let totalKeyDeleted = 0;
        let totalKeyWouldDelete = 0;

        for (const tableName of allTables) {
            const result = this.checkKeyIntegrity(tableName, simulate);
            keyResults.push(result);
            totalKeyIssues += result.totalIssues;
            totalKeyDeleted += result.deleted || 0;
            totalKeyWouldDelete += result.wouldDelete || 0;
        }

        // Step 2: Check foreign key consistency (only for tables with FK relationships)
        Logger.log('\n' + '-'.repeat(80));
        Logger.log('STEP 2: FOREIGN KEY CONSISTENCY VALIDATION');
        Logger.log('-'.repeat(80));

        // Process tables in reverse dependency order (children before parents)
        // This ensures that when we delete a parent, we've already cleaned up its children
        const processingOrder = [
            'manufacturer_materials',    // depends on: manufacturers, materials (base tables)
            'vendor_price_lists',        // depends on: manufacturer_materials, vendors
            'purchase_orders',           // depends on: vendors (parent - delete last)
            'purchase_order_items',      // depends on: purchase_orders, manufacturer_materials, materials (child - delete first)
            'purchase_order_payments',   // depends on: purchase_orders (child - delete first)
            'baskets',            // basket parent (delete last among basket tables)
            'basket_items',              // depends on: baskets, manufacturer_materials (child)
            'quotations',            // depends on: baskets, vendors (child)
            'quotation_items',       // depends on: quotations, basket_items, baskets, vendor_price_lists (most dependent child)
        ];

        const fkResults = [];
        let totalFKInvalid = 0;
        let totalFKDeleted = 0;
        let totalFKWouldDelete = 0;

        for (const tableName of processingOrder) {
            const result = this.checkAndCleanTable(tableName, simulate);
            fkResults.push(result);
            totalFKInvalid += result.invalidRecords.length;
            totalFKDeleted += result.deleted || 0;
            totalFKWouldDelete += result.wouldDelete || 0;
        }

        // Combine results
        const results = [...keyResults, ...fkResults];
        const totalInvalid = totalKeyIssues + totalFKInvalid;
        const totalDeleted = totalKeyDeleted + totalFKDeleted;
        const totalWouldDelete = totalKeyWouldDelete + totalFKWouldDelete;

        // Summary
        Logger.log('\n' + '='.repeat(80));
        Logger.log('COMPREHENSIVE CONSISTENCY CHECK SUMMARY - ' + mode);
        Logger.log('='.repeat(80));
        Logger.log(`Tables checked: ${allTables.length}`);
        Logger.log(`\nKey Integrity Issues:`);
        Logger.log(`  - NULL/Empty Keys: ${keyResults.reduce((sum, r) => sum + r.nullKeys, 0)}`);
        Logger.log(`  - Duplicate Keys: ${keyResults.reduce((sum, r) => sum + r.duplicateKeys, 0)} (${keyResults.reduce((sum, r) => sum + r.duplicateRows, 0)} duplicate rows)`);
        Logger.log(`  - Total Key issues: ${totalKeyIssues}`);

        Logger.log(`\nForeign Key Violations:`);
        Logger.log(`  - Invalid references: ${totalFKInvalid}`);

        Logger.log(`\nOverall Totals:`);
        Logger.log(`  - Total issues found: ${totalInvalid}`);

        if (simulate) {
            Logger.log(`  - Total records that WOULD BE deleted: ${totalWouldDelete}`);
        } else {
            Logger.log(`  - Total records deleted: ${totalDeleted}`);
        }

        Logger.log('='.repeat(80));
        Logger.log('\nKey Integrity Results:');

        for (const result of keyResults) {
            if (result.totalIssues > 0) {
                const issues = [];
                if (result.nullKeys > 0) issues.push(`${result.nullKeys} null`);
                if (result.duplicateKeys > 0) issues.push(`${result.duplicateKeys} duplicates`);

                if (simulate) {
                    Logger.log(`  ${result.tableName} (${result.keyColumn}): ${issues.join(', ')} (would delete ${result.wouldDelete})`);
                } else {
                    Logger.log(`  ${result.tableName} (${result.keyColumn}): ${issues.join(', ')} (deleted ${result.deleted})`);
                }
            } else {
                Logger.log(`  ${result.tableName} (${result.keyColumn}): ✓ Key integrity OK`);
            }
        }

        Logger.log('\nForeign Key Consistency Results:');

        for (const result of fkResults) {
            if (result.invalidRecords && result.invalidRecords.length > 0) {
                if (simulate) {
                    Logger.log(`  ${result.tableName}: ${result.invalidRecords.length} invalid references (would delete ${result.wouldDelete})`);
                } else {
                    Logger.log(`  ${result.tableName}: ${result.invalidRecords.length} invalid references (deleted ${result.deleted})`);
                }
            } else {
                Logger.log(`  ${result.tableName}: ✓ FK consistency OK`);
            }
        }

        Logger.log('\n' + '='.repeat(80));

        if (totalInvalid === 0) {
            Logger.log('✓✓✓ All tables are fully consistent! No issues found.');
            Logger.log('  • All primary keys are valid and unique');
            Logger.log('  • All foreign key references are valid');
        } else if (simulate) {
            Logger.log(`⚠⚠⚠ SIMULATION COMPLETE`);
            Logger.log(`Found ${totalInvalid} total issues:`);
            Logger.log(`  • Key issues: ${totalKeyIssues}`);
            Logger.log(`  • Foreign key violations: ${totalFKInvalid}`);
            Logger.log(`${totalWouldDelete} records would be deleted if cleanup is performed`);
            Logger.log(`\nTo perform actual cleanup, call: consistencyChecks.checkAndCleanAllTables(false)`);
        } else {
            Logger.log(`✓✓✓ CLEANUP COMPLETE!`);
            Logger.log(`Successfully deleted ${totalDeleted} invalid records:`);
            Logger.log(`  • Key issues fixed: ${totalKeyDeleted}`);
            Logger.log(`  • Foreign key violations fixed: ${totalFKDeleted}`);
        }

        Logger.log('='.repeat(80) + '\n');

        if (execContext.canShowToast) {
            if (totalInvalid === 0) {
                ss.toast('All tables are consistent!', 'Consistency Check Complete', 5);
            } else if (simulate) {
                ss.toast(`Found ${totalInvalid} invalid records (simulation)`, 'Check Complete', 5);
            } else {
                ss.toast(`Deleted ${totalDeleted} invalid records`, 'Cleanup Complete', 5);
            }
        }

        return {
            timestamp: new Date().toISOString(),
            mode: simulate ? 'simulation' : 'cleanup',
            tablesChecked: allTables.length,
            keyIssues: {
                nullKeys: keyResults.reduce((sum, r) => sum + r.nullKeys, 0),
                duplicateKeys: keyResults.reduce((sum, r) => sum + r.duplicateKeys, 0),
                duplicateRows: keyResults.reduce((sum, r) => sum + r.duplicateRows, 0),
                total: totalKeyIssues,
                deleted: totalKeyDeleted,
                wouldDelete: totalKeyWouldDelete
            },
            foreignKeyIssues: {
                total: totalFKInvalid,
                deleted: totalFKDeleted,
                wouldDelete: totalFKWouldDelete
            },
            totalInvalid,
            totalDeleted,
            totalWouldDelete,
            simulate,
            keyResults,
            foreignKeyResults: fkResults
        };
    },

    /**
     * Generate a detailed report of consistency issues without deleting (simulation mode)
     */
    generateConsistencyReport() {
        const report = this.checkAndCleanAllTables(true);
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const execContext = utils.getExecutionContext();

        if (execContext.canShowAlert) {
            if (report.totalInvalid === 0) {
                SpreadsheetApp.getUi().alert(
                    'Consistency Check Complete',
                    'All data is consistent!\n\n✓ All primary keys are valid and unique\n✓ All foreign key references are valid',
                    SpreadsheetApp.getUi().ButtonSet.OK
                );
            } else {
                const messageParts = [];

                // Key issues
                if (report.keyIssues.total > 0) {
                    messageParts.push('Primary Key Integrity Issues:');
                    const keyIssues = report.keyResults
                        .filter(r => r.totalIssues > 0)
                        .map(r => {
                            const issues = [];
                            if (r.nullKeys > 0) issues.push(`${r.nullKeys} null`);
                            if (r.duplicateKeys > 0) issues.push(`${r.duplicateKeys} duplicates`);
                            return `• ${r.tableName} (${r.keyColumn}): ${issues.join(', ')}`;
                        });
                    messageParts.push(...keyIssues);
                    messageParts.push('');
                }

                // Foreign key issues
                if (report.foreignKeyIssues.total > 0) {
                    messageParts.push('Foreign Key Violations:');
                    const fkIssues = report.foreignKeyResults
                        .filter(r => r.invalidRecords && r.invalidRecords.length > 0)
                        .map(r => `• ${r.tableName}: ${r.invalidRecords.length} invalid references`);
                    messageParts.push(...fkIssues);
                    messageParts.push('');
                }

                messageParts.push(`Total: ${report.totalInvalid} issues found (${report.totalWouldDelete} records would be deleted)`);
                messageParts.push('');
                messageParts.push('Use "Clean Data Consistency" to fix these issues.');

                SpreadsheetApp.getUi().alert(
                    'Consistency Issues Found',
                    messageParts.join('\n'),
                    SpreadsheetApp.getUi().ButtonSet.OK
                );
            }
        }
    },

    /**
     * Display record count statistics in a dialog
     */
    displayRecordCountStatistics() {
        const stats = this.getRecordCountStatistics();
        const execContext = utils.getExecutionContext();

        if (!execContext.canShowAlert) {
            Logger.log('Cannot show dialog in current context');
            return;
        }

        const ui = SpreadsheetApp.getUi();
        const messageParts = [];

        // Sort tables by name for consistent display
        const sortedTables = Object.keys(stats.tables).sort();

        messageParts.push('RECORD COUNT BY TABLE');
        messageParts.push('='.repeat(40));
        messageParts.push('');

        for (const tableName of sortedTables) {
            const tableStats = stats.tables[tableName];

            if (tableStats.status === 'ok') {
                messageParts.push(`${tableName}: ${tableStats.count}`);
            } else if (tableStats.status === 'empty') {
                messageParts.push(`${tableName}: 0 (empty)`);
            } else if (tableStats.status === 'not_found') {
                messageParts.push(`${tableName}: 0 (not found)`);
            } else {
                messageParts.push(`${tableName}: 0 (${tableStats.status})`);
            }
        }

        messageParts.push('');
        messageParts.push('='.repeat(40));
        messageParts.push(`TOTAL RECORDS: ${stats.totalRecords}`);
        messageParts.push('');
        messageParts.push(`Timestamp: ${new Date(stats.timestamp).toLocaleString()}`);

        ui.alert(
            'Record Count Statistics',
            messageParts.join('\n'),
            ui.ButtonSet.OK
        );
    },

    /**
     * Menu function to check and clean all consistency issues
     */
    performConsistencyCleanup() {
        const execContext = utils.getExecutionContext();
        if (execContext.canShowAlert) {
            const ui = SpreadsheetApp.getUi();
            const response = ui.alert(
                'Clean Data Consistency',
                'This will delete all records with invalid foreign key references.\n\nThis action cannot be undone.\n\nDo you want to continue?',
                ui.ButtonSet.YES_NO
            );

            if (response !== ui.Button.YES) {
                ui.alert('Operation cancelled');
                return;
            }
        }

        const summary = this.checkAndCleanAllTables(false);

        if (execContext.canShowAlert) {
            if (summary.totalDeleted > 0) {
                SpreadsheetApp.getUi().alert(
                    'Cleanup Complete',
                    `Successfully deleted ${summary.totalDeleted} invalid records.\n\nCheck the logs for details.`,
                    SpreadsheetApp.getUi().ButtonSet.OK
                );
            } else if (summary.totalInvalid === 0) {
                SpreadsheetApp.getUi().alert(
                    'No Issues Found',
                    'All data is already consistent!',
                    SpreadsheetApp.getUi().ButtonSet.OK
                );
            }
        }
    }
};