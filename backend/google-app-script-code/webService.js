
/**
 * Unified POST endpoint handler for all operations
 * Secret code is sent in request body for better security (not in URL)
 * Supports both 'pull' (download) and 'push' (upload) operations
 */
function doPost(e) {
    try {
        const params = JSON.parse(e.postData.contents);
        const secretCode = params.secret;
        const operation = params.operation; // 'delta_pull' or 'delta_push'
        // Validate secret code
        webSecurity.validateSecretCode(secretCode);

        if (operation === "login") {
            // Login/credential validation - just return success if secret is valid
            return ContentService.createTextOutput(
                JSON.stringify({
                    success: true,
                    message: "Credentials validated successfully"
                })
            ).setMimeType(ContentService.MimeType.JSON);
        } else if (operation === "checkSheetSetup") {
            const statisticsSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(setup.SHEET_NAMES.STATISTICS);
            return ContentService.createTextOutput(
                JSON.stringify({
                    result: statisticsSheet?.getRange(1, 5)?.getValue() === true
                })
            ).setMimeType(ContentService.MimeType.JSON);
        } else if (operation === "setupSheets") {
            setup.setupSheets();
            return ContentService.createTextOutput(
                JSON.stringify({
                    success: true,
                    message: "Setup completed successfully"
                })
            ).setMimeType(ContentService.MimeType.JSON);
        } else if (operation === "delta_pull") {
            // Delta sync: Pull changes from server using change_log with pagination
            const sinceEpochTimeMilliseconds = utils.getEpochTimeMilliseconds(params?.since, EPOCH_TIME_LOWEST_MILLISECONDS);
            const offset = params.offset != null ? parseInt(params.offset, 10) : 0;
            const limit = params.limit != null ? parseInt(params.limit, 10) : 200;

            // If offset is 0, consolidate change log
            if (offset === 0) {
                Logger.log('Consolidating change log into condensed_change_log');
                changeLog.writeCondensedChangeLog(sinceEpochTimeMilliseconds);
            }

            // Read condensed change log with pagination
            const { log, totalRecords } = changeLog.readCondensedChangeLog(offset, limit);

            // Fetch actual records for insert/update operations
            const tableRecords = deltaSync.fetchTableRecordsForChanges(log);

            return ContentService.createTextOutput(
                JSON.stringify({
                    success: true,
                    log: log,
                    totalRecords: totalRecords,
                    tableRecords: tableRecords
                })
            ).setMimeType(ContentService.MimeType.JSON);
        } else if (operation === "delta_push") {
            // Delta sync: Push changes to server using change_log with batch operations
            const log = params.log;
            const tableRecords = params.tableRecords;

            if (!log) {
                return ContentService.createTextOutput(
                    JSON.stringify({ error: "Missing log parameter" })
                ).setMimeType(ContentService.MimeType.JSON);
            }

            const result = deltaSync.applyDeltaChangesBatch(log, tableRecords);

            return ContentService.createTextOutput(
                JSON.stringify({ success: true, processed: result })
            ).setMimeType(ContentService.MimeType.JSON);
        } else {
            return ContentService.createTextOutput(
                JSON.stringify({
                    error:
                        'Invalid operation. Use "login", "delta_pull", or "delta_push"',
                })
            ).setMimeType(ContentService.MimeType.JSON);
        }
    } catch (error) {
        return ContentService.createTextOutput(
            JSON.stringify({ error: error.toString() })
        ).setMimeType(ContentService.MimeType.JSON);
    }
}

/**
 * GET endpoint - redirects to inform users to use POST
 * Google Apps Script web apps don't support custom HTTP headers,
 * so we use POST for all operations to keep secret in body
 */
function doGet(e) {
    return HtmlService.createHtmlOutputFromFile('welcome');
}