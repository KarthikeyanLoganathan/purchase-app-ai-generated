const zlocalTests = {
    zTestClearDataValidations() {
        const ss = SpreadsheetApp.getActive();
        ss.getActiveSheet().getDataRange().clearDataValidations();
    },

    zTestSyncInBackend() {
        const { log, totalRecords } = changeLog.readCondensedChangeLog(0, 200);
        const tableRecords = deltaSync.fetchTableRecordsForChanges(log);
        console.log("done");
    },

    /**
     * Debug function to check what's in the change logs for specific tables
     */
    zDebugChangeLogs() {
        const ss = SpreadsheetApp.getActiveSpreadsheet();

        // Check change_log
        const changeLogSheet = ss.getSheetByName('change_log');
        if (changeLogSheet) {
            const data = changeLogSheet.getDataRange().getValues();
            const uomChanges = data.filter(row => row[1] === 101); // table_index for unit_of_measures
            const currencyChanges = data.filter(row => row[1] === 102); // table_index for currencies

            Logger.log(`=== CHANGE_LOG ===`);
            Logger.log(`Total rows: ${data.length - 1}`);
            Logger.log(`unit_of_measures (101) entries: ${uomChanges.length}`);
            Logger.log(`currencies (102) entries: ${currencyChanges.length}`);

            if (uomChanges.length > 0) {
                Logger.log('Sample unit_of_measures entry: ' + JSON.stringify(uomChanges[0]));
            }
            if (currencyChanges.length > 0) {
                Logger.log('Sample currencies entry: ' + JSON.stringify(currencyChanges[0]));
            }
        }

        // Check condensed_change_log
        const condensedSheet = ss.getSheetByName('condensed_change_log');
        if (condensedSheet) {
            const data = condensedSheet.getDataRange().getValues();
            const uomChanges = data.filter(row => row[1] === 101);
            const currencyChanges = data.filter(row => row[1] === 102);

            Logger.log(`\n=== CONDENSED_CHANGE_LOG ===`);
            Logger.log(`Total rows: ${data.length - 1}`);
            Logger.log(`unit_of_measures (101) entries: ${uomChanges.length}`);
            Logger.log(`currencies (102) entries: ${currencyChanges.length}`);

            if (uomChanges.length > 0) {
                Logger.log('Sample unit_of_measures entry: ' + JSON.stringify(uomChanges[0]));
            }
            if (currencyChanges.length > 0) {
                Logger.log('Sample currencies entry: ' + JSON.stringify(currencyChanges[0]));
            }
        }

        // Check actual data in the tables
        const uomSheet = ss.getSheetByName('unit_of_measures');
        const currSheet = ss.getSheetByName('currencies');

        Logger.log(`\n=== ACTUAL DATA ===`);
        if (uomSheet) {
            Logger.log(`unit_of_measures rows: ${uomSheet.getLastRow() - 1}`);
        }
        if (currSheet) {
            Logger.log(`currencies rows: ${currSheet.getLastRow() - 1}`);
        }

        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast('Check logs for debug info');
        }
    },

    /**
     * Test function to simulate what the client receives during delta_pull
     */
    zTestDeltaPull() {
        Logger.log('=== SIMULATING DELTA PULL ===');

        // Simulate the delta_pull operation
        const sinceEpochTimeMilliseconds = EPOCH_TIME_LOWEST_MILLISECONDS;
        const offset = 0;
        const limit = 200;

        // Step 1: Write condensed change log (happens when offset = 0)
        Logger.log('\nStep 1: Writing condensed change log...');
        changeLog.writeCondensedChangeLog(sinceEpochTimeMilliseconds);

        // Step 2: Read condensed change log
        Logger.log('\nStep 2: Reading condensed change log...');
        const { log, totalRecords } = changeLog.readCondensedChangeLog(offset, limit);
        Logger.log(`Total records in condensed log: ${totalRecords}`);
        Logger.log(`Records in this batch: ${log.length}`);

        // Check for unit_of_measures and currencies
        const uomEntries = log.filter(entry => entry.table_index === 101);
        const currencyEntries = log.filter(entry => entry.table_index === 102);

        Logger.log(`\nunit_of_measures (101) in response: ${uomEntries.length}`);
        Logger.log(`currencies (102) in response: ${currencyEntries.length}`);

        if (uomEntries.length > 0) {
            Logger.log('unit_of_measures entries: ' + JSON.stringify(uomEntries));
        }
        if (currencyEntries.length > 0) {
            Logger.log('currencies entries: ' + JSON.stringify(currencyEntries));
        }

        // Step 3: Fetch actual records
        Logger.log('\nStep 3: Fetching table records...');
        const tableRecords = deltaSync.fetchTableRecordsForChanges(log);

        Logger.log(`\nTables with records: ${Object.keys(tableRecords).join(', ')}`);

        if (tableRecords.unit_of_measures) {
            Logger.log(`unit_of_measures records: ${Object.keys(tableRecords.unit_of_measures).length}`);
            Logger.log('Sample: ' + JSON.stringify(Object.values(tableRecords.unit_of_measures)[0]));
        } else {
            Logger.log('unit_of_measures: NOT IN RESPONSE');
        }

        if (tableRecords.currencies) {
            Logger.log(`currencies records: ${Object.keys(tableRecords.currencies).length}`);
            Logger.log('Sample: ' + JSON.stringify(Object.values(tableRecords.currencies)[0]));
        } else {
            Logger.log('currencies: NOT IN RESPONSE');
        }

        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast('Check logs for delta pull simulation');
        }
    }
};

function zTestSetupSheets(){
  setup.setupSheets()
}