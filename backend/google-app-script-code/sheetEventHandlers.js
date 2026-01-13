/**
 * Setup function to create all required sheets matching SQLite database structure
 * Run this function once to initialize the Google Sheet
 */
function onOpen() {
    const scriptId = ScriptApp.getScriptId();
    const sheet = SpreadsheetApp.getActiveSpreadsheet();
    // Save to a hidden "Metadata" sheet or Developer Metadata
    sheet.addDeveloperMetadata('theGoogleAppScriptId', scriptId);    
    const ui = SpreadsheetApp.getUi();
    ui.createMenu("Purchase App")
        .addItem("Fill UUID", `${utils.fillUUID.name}`)
        .addItem("Normalize Texts in Selected Column", `utils.${utils.normalizeTextsInSelectedColumn.name}`)
        .addSeparator()
        .addItem("Display Record Statistics", `consistencyChecks.${consistencyChecks.displayRecordCountStatistics.name}`)
        .addItem("Do Consistency Checks", `consistencyChecks.${consistencyChecks.generateConsistencyReport.name}`)
        .addItem("Perform Consistency Cleanup", `consistencyChecks.${consistencyChecks.performConsistencyCleanup.name}`)
        .addSeparator()
        .addItem("Export Current Sheet to CSV", `csvExport.${csvExport.exportCurrentSheet.name}`)
        .addItem("Export All Data Sheets to ZIP", `csvExport.${csvExport.exportAllDataSheets.name}`)
        .addSeparator()
        .addItem("Cleanup Current Sheet", `cleanup.${cleanup.cleanupCurrentSheet.name}`)
        .addItem("Cleanup Transaction Data Sheets", `cleanup.${cleanup.cleanupTransactionDataSheets.name}`)
        .addItem("Cleanup Log Data Sheets", `cleanup.${cleanup.cleanupLogDataSheets.name}`)
        .addItem("Cleanup All Data Sheets", `cleanup.${cleanup.cleanupAllDataSheets.name}`)
        .addSeparator()
        .addItem("Initialize Change Log from Data Sheets", `changeLog.${changeLog.initializeChangeLogFromDataSheets.name}`)
        .addItem("Write Condensed Change Log", `changeLog.${changeLog.writeCondensedChangeLogForAllData.name}`)
        .addSeparator()
        .addItem("Setup Sheets", `setup.${setup.setupSheets.name}`)
        .addItem("Setup Schema for Current Sheet", `setup.${setup.setupDataTableSheetForCurrentSheet.name}`)
        .addSeparator()
        .addItem("Setup Maintain Manufacturer Material Models - Input Sheet", `maintainManufacturerModelNames.${maintainManufacturerModelNames.setupSheet.name}`)
        .addItem("Setup Maintain Manufacturer Material Model Data - Input Sheet", `maintainManufacturerModelData.${maintainManufacturerModelData.setupSheet.name}`)
        .addItem("Setup Maintain Vendor Price Lists - Input Sheet", `maintainVendorPriceLists.${maintainVendorPriceLists.setupSheet.name}`)
        .addSeparator()
        .addItem("Deploy Web App", `deployer.${deployer.deployWebApp.name}`)
        .addToUi();
}

/**
 * Handle checkbox clicks on the utility sheet buttons
 */
function onEdit(e) {
    try {
        const range = e.range;
        const sheet = range.getSheet();
        const sheetName = sheet.getName();

        if (sheetName === maintainManufacturerModelNames.LAYOUT.SHEET) {
            maintainManufacturerModelNames.onEdit(range);
        } else if (sheetName === maintainManufacturerModelData.LAYOUT.SHEET) {
            maintainManufacturerModelData.onEdit(range);
        } else if (sheetName === maintainVendorPriceLists.LAYOUT.SHEET) {
            maintainVendorPriceLists.onEdit(range);
        }
    } catch (error) {
        Logger.log("Error in onEdit: " + error.toString());
        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Error: " + error.toString());
        }
    }
}
