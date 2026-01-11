const csvExport = {
  /**
   * Generate CSV content from sheet data
   * @param {Array} data - Sheet data array
   * @param {string} sheetName - Name of the sheet
   * @returns {string} CSV content
   */
  _generateCsvContent(data, sheetName) {
    if (data.length < 1) {
      return "";
    }

    const tableColumns = tableDefinitions.getByName(sheetName)?.columnNames;
    const baseColumns = tableColumns || data[0];
    const colIndices = baseColumns
      .map((col) => data[0].indexOf(col))
      .filter((idx) => idx !== -1);

    const csvRows = [];

    for (let i = 0; i < data.length; i++) {
      const row = data[i];

      // Skip empty rows (except header)
      if (i > 0 && row.every(cell => cell === null || cell === undefined || String(cell).trim() === "")) {
        continue;
      }

      // Only include base columns in CSV
      const csvRow = colIndices.map((index) => {
        let value = row[index];

        // Format dates specifically
        if (value instanceof Date) {
          value = value.toISOString();
        } else if (
          typeof value === "string" &&
          tableDefinitions.getByName(sheetName)?.isDateColumn(baseColumns[colIndices.indexOf(index)])
        ) {
          // Double check if it's a date string that needs normalization
          try {
            const d = new Date(value);
            if (!isNaN(d.getTime())) {
              value = d.toISOString();
            }
          } catch (e) { 
            Logger.log('Date parsing error: ' + e.toString());
          }
        }

        // Escape quotes and wrap in quotes if necessary
        let stringValue =
          value === null || value === undefined ? "" : String(value);
        if (
          stringValue.includes(",") ||
          stringValue.includes('"') ||
          stringValue.includes("\n")
        ) {
          stringValue = '"' + stringValue.replace(/"/g, '""') + '"';
        }
        return stringValue;
      });

      csvRows.push(csvRow.join(","));
    }

    return csvRows.join("\r\n");
  },

  /**
   * Export current sheet to CSV format with ISO 8601 dates
   */
  exportCurrentSheet() {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getActiveSheet();
    const sheetName = sheet.getName();
    const data = sheet.getDataRange().getValues();
    const execContext = utils.getExecutionContext();

    if (!execContext.isSheetsUI) {
      throw new Error("CSV Export is only supported in Sheets UI.");
    }
    if (data.length < 1) {
      if (execContext.canShowToast) {
        SpreadsheetApp.getActiveSpreadsheet().toast("The sheet is empty.");
      }
      return;
    }

    const csvContent = this._generateCsvContent(data, sheetName);
    const filename = sheetName + ".csv";
    showDownloadDialog(csvContent, filename);

    /**
     * Helper to show a download dialog for the generated CSV
     */
    function showDownloadDialog(content, filename) {
      const htmlContent = `
      <html>
        <body>
          <p>Your CSV file is ready for download.</p>
          <a id="downloadLink" href="#" download="${filename}">Click here to download if it doesn't start automatically</a>
          <script>
            const content = ${JSON.stringify(content)};
            const blob = new Blob([content], {type: 'text/csv'});
            const url = URL.createObjectURL(blob);
            const link = document.getElementById('downloadLink');
            link.href = url;
            link.click();
            // Close dialog after a delay
            setTimeout(() => { google.script.host.close(); }, 3000);
          </script>
        </body>
      </html>
    `;

      const html = HtmlService.createHtmlOutput(htmlContent)
        .setWidth(400)
        .setHeight(150);

      SpreadsheetApp.getUi().showModalDialog(html, "Downloading CSV...");
    }
  },

  /**
   * Export all configuration, master data, and transaction data sheets to a zip file
   * Shows a UI dialog to let users choose which table types to export
   */
  exportAllDataSheets() {
    const htmlContent = `
      <html>
        <head>
          <base target="_top">
          <style>
            body {
              font-family: Arial, sans-serif;
              padding: 20px;
            }
            .checkbox-group {
              margin: 15px 0;
            }
            .checkbox-item {
              margin: 10px 0;
              display: flex;
              align-items: center;
            }
            .checkbox-item input {
              margin-right: 10px;
              width: 18px;
              height: 18px;
              cursor: pointer;
            }
            .checkbox-item label {
              cursor: pointer;
              user-select: none;
            }
            .button-group {
              margin-top: 20px;
              display: flex;
              gap: 10px;
            }
            button {
              padding: 10px 20px;
              font-size: 14px;
              cursor: pointer;
              border: none;
              border-radius: 4px;
            }
            .export-btn {
              background-color: #4CAF50;
              color: white;
            }
            .export-btn:hover {
              background-color: #45a049;
            }
            .export-btn:disabled {
              background-color: #cccccc;
              cursor: not-allowed;
            }
            .cancel-btn {
              background-color: #f44336;
              color: white;
            }
            .cancel-btn:hover {
              background-color: #da190b;
            }
            .select-all {
              font-weight: bold;
              color: #1a73e8;
              border-bottom: 2px solid #e0e0e0;
              padding-bottom: 10px;
            }
            .message {
              color: #d32f2f;
              font-size: 13px;
              margin-top: 10px;
              display: none;
            }
          </style>
        </head>
        <body>
          <h3>Select Table Types to Export</h3>
          <div class="checkbox-group">
            <div class="checkbox-item select-all">
              <input type="checkbox" id="selectAll" onchange="toggleAll(this)">
              <label for="selectAll">Select All</label>
            </div>
            <div class="checkbox-item">
              <input type="checkbox" class="type-checkbox" id="METADATA" value="METADATA" onchange="updateSelectAll()">
              <label for="METADATA">Metadata</label>
            </div>
            <div class="checkbox-item">
              <input type="checkbox" class="type-checkbox" id="CONFIGURATION_DATA" value="CONFIGURATION_DATA" onchange="updateSelectAll()" checked>
              <label for="CONFIGURATION_DATA">Configuration Data</label>
            </div>
            <div class="checkbox-item">
              <input type="checkbox" class="type-checkbox" id="MASTER_DATA" value="MASTER_DATA" onchange="updateSelectAll()" checked>
              <label for="MASTER_DATA">Master Data</label>
            </div>
            <div class="checkbox-item">
              <input type="checkbox" class="type-checkbox" id="TRANSACTION_DATA" value="TRANSACTION_DATA" onchange="updateSelectAll()" checked>
              <label for="TRANSACTION_DATA">Transaction Data</label>
            </div>
            <div class="checkbox-item">
              <input type="checkbox" class="type-checkbox" id="LOG" value="LOG" onchange="updateSelectAll()">
              <label for="LOG">Logs</label>
            </div>
          </div>
          <div class="message" id="message">Please select at least one table type</div>
          <div class="button-group">
            <button class="export-btn" onclick="exportSelected()">Export</button>
            <button class="cancel-btn" onclick="google.script.host.close()">Cancel</button>
          </div>
          
          <script>
            function toggleAll(checkbox) {
              const checkboxes = document.querySelectorAll('.type-checkbox');
              checkboxes.forEach(cb => cb.checked = checkbox.checked);
              updateMessage();
            }
            
            function updateSelectAll() {
              const checkboxes = document.querySelectorAll('.type-checkbox');
              const selectAll = document.getElementById('selectAll');
              const allChecked = Array.from(checkboxes).every(cb => cb.checked);
              selectAll.checked = allChecked;
              updateMessage();
            }
            
            function updateMessage() {
              const checkboxes = document.querySelectorAll('.type-checkbox');
              const anyChecked = Array.from(checkboxes).some(cb => cb.checked);
              document.getElementById('message').style.display = anyChecked ? 'none' : 'block';
            }
            
            function exportSelected() {
              const checkboxes = document.querySelectorAll('.type-checkbox:checked');
              const selectedTypes = Array.from(checkboxes).map(cb => cb.value);
              
              if (selectedTypes.length === 0) {
                document.getElementById('message').style.display = 'block';
                return;
              }
              
              // Call the server-side function with selected types
              google.script.run
                .withSuccessHandler(() => {
                  // Dialog will be closed by the download dialog
                })
                .withFailureHandler((error) => {
                  alert('Error: ' + error.message);
                  google.script.host.close();
                })
                .csvExportOfDataSheetsBySelectedTypes(selectedTypes);
            }
            
            // Initialize
            updateSelectAll();
            updateMessage();
          </script>
        </body>
      </html>
    `;

    const html = HtmlService.createHtmlOutput(htmlContent)
      .setWidth(450)
      .setHeight(400);

    SpreadsheetApp.getUi().showModalDialog(html, "Export Data Sheets");
  },

  /**
   * Export data sheets filtered by selected table types
   * @param {string[]} selectedTypes - Array of table type strings to export
   */
  exportDataSheetsByTypes(selectedTypes) {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const execContext = utils.getExecutionContext();
    const blobs = [];
    let exportedCount = 0;
    if (!execContext.isSheetsUI) {
      throw new Error("CSV Export is only supported in Sheets UI.");
    }

    for (const tableName of tableDefinitions.tableNames) {
      // Skip tables that are not in selected types
      // @ts-ignore - tableDef.TYPE is a valid TABLE_TYPES value
      const tableDef = tableDefinitions.getByName(tableName);
      if (!selectedTypes.includes(tableDef.type)) {
        continue;
      }

      const sheet = ss.getSheetByName(tableName);
      if (!sheet) {
        Logger.log(`Sheet "${tableName}" not found, skipping...`);
        continue;
      }

      const data = sheet.getDataRange().getValues();
      if (data.length < 1) {
        Logger.log(`Sheet "${tableName}" is empty, skipping...`);
        continue;
      }

      // Generate CSV content for this sheet
      const csvContent = this._generateCsvContent(data, tableName);

      // Create blob for this CSV
      const blob = Utilities.newBlob(csvContent, 'text/csv', tableName + '.csv');
      blobs.push(blob);
      exportedCount++;
      Logger.log(`Exported "${tableName}" (${data.length} rows)`);
    }

    if (blobs.length === 0) {
      if (execContext.canShowToast) {
        SpreadsheetApp.getActiveSpreadsheet().toast("No data sheets found to export.");
      }
      return;
    }

    // Create zip file containing all CSV files
    const zipBlob = Utilities.zip(blobs, 'data.zip');

    // Convert to base64 for download
    const base64Data = Utilities.base64Encode(zipBlob.getBytes());

    showZipDownloadDialog(base64Data, exportedCount);

    /**
     * Helper to show a download dialog for the generated ZIP
     */
    function showZipDownloadDialog(base64Data, count) {
      const htmlContent = `
      <html>
        <body>
          <p>Your ZIP file with ${count} CSV files is ready for download.</p>
          <a id="downloadLink" href="#" download="data.zip">Click here to download if it doesn't start automatically</a>
          <script>
            const base64Data = "${base64Data}";
            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
              byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], {type: 'application/zip'});
            const url = URL.createObjectURL(blob);
            const link = document.getElementById('downloadLink');
            link.href = url;
            link.click();
            // Close dialog after a delay
            setTimeout(() => { google.script.host.close(); }, 3000);
          </script>
        </body>
      </html>
    `;

      const html = HtmlService.createHtmlOutput(htmlContent)
        .setWidth(400)
        .setHeight(150);

      SpreadsheetApp.getUi().showModalDialog(html, "Downloading ZIP...");
    }
  }
};

/**
 * Global function to export data sheets by selected types
 * This is a wrapper that can be called from google.script.run
 * @param {string[]} selectedTypes - Array of table type strings to export
 */
function csvExportOfDataSheetsBySelectedTypes(selectedTypes) {
  csvExport.exportDataSheetsByTypes(selectedTypes);
}
