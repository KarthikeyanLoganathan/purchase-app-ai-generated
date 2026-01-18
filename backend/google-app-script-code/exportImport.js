const exportImport = {
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
   * Parse CSV string into array of arrays
   * @param {string} csvString - CSV content to parse
   * @returns {Array} Parsed data array
   */
  _parseCsvContent(csvString) {
    const rows = [];
    let currentRow = [];
    let currentField = '';
    let inQuotes = false;
    
    for (let i = 0; i < csvString.length; i++) {
      const char = csvString[i];
      const nextChar = csvString[i + 1];
      
      if (inQuotes) {
        if (char === '"') {
          if (nextChar === '"') {
            // Escaped quote
            currentField += '"';
            i++; // Skip next quote
          } else {
            // End of quoted field
            inQuotes = false;
          }
        } else {
          currentField += char;
        }
      } else {
        if (char === '"') {
          // Start of quoted field
          inQuotes = true;
        } else if (char === ',') {
          // Field separator
          currentRow.push(currentField);
          currentField = '';
        } else if (char === '\r' && nextChar === '\n') {
          // Windows line ending
          currentRow.push(currentField);
          rows.push(currentRow);
          currentRow = [];
          currentField = '';
          i++; // Skip \n
        } else if (char === '\n' || char === '\r') {
          // Unix/Mac line ending
          currentRow.push(currentField);
          rows.push(currentRow);
          currentRow = [];
          currentField = '';
        } else {
          currentField += char;
        }
      }
    }
    
    // Add last field and row if any
    if (currentField || currentRow.length > 0) {
      currentRow.push(currentField);
      rows.push(currentRow);
    }
    
    return rows;
  },

  /**
   * Import CSV data into a specific table sheet
   * @param {string} tableName - Name of the table/sheet to import into
   * @param {string} csvDataString - CSV content string with UTC dates
   */
  csvImportTableData(tableName, csvDataString) {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const tableDef = tableDefinitions.getByName(tableName);
    
    if (!tableDef) {
      throw new Error(`Table "${tableName}" not found in table definitions.`);
    }
    
    // Parse CSV content
    const parsedData = this._parseCsvContent(csvDataString);
    
    if (parsedData.length === 0) {
      throw new Error("CSV data is empty.");
    }
    
    // Validate header row matches expected columns
    const csvHeaders = parsedData[0];
    const expectedColumns = tableDef.columnNames;
    
    // Check if all expected columns are present in CSV
    const missingColumns = expectedColumns.filter(col => !csvHeaders.includes(col));
    if (missingColumns.length > 0) {
      throw new Error(`Missing required columns: ${missingColumns.join(', ')}`);
    }
    
    // Create column mapping (CSV column index to sheet column index)
    const columnMapping = csvHeaders.map(csvCol => {
      const expectedIndex = expectedColumns.indexOf(csvCol);
      return {
        csvIndex: csvHeaders.indexOf(csvCol),
        sheetIndex: expectedIndex !== -1 ? expectedIndex : null,
        columnName: csvCol,
        isDateColumn: tableDef.isDateColumn(csvCol)
      };
    }).filter(mapping => mapping.sheetIndex !== null);
    
    // Process data rows
    const processedData = [];
    
    // Add header row (create a copy to avoid readonly issues)
    processedData.push([...expectedColumns]);
    
    // Process each data row
    for (let i = 1; i < parsedData.length; i++) {
      const csvRow = parsedData[i];
      const sheetRow = new Array(expectedColumns.length).fill('');
      
      for (const mapping of columnMapping) {
        let value = csvRow[mapping.csvIndex];
        
        // Convert empty strings to empty values
        if (value === '') {
          sheetRow[mapping.sheetIndex] = '';
          continue;
        }
        
        // Convert UTC date strings back to Date objects
        if (mapping.isDateColumn && value) {
          try {
            const dateValue = new Date(value);
            if (!isNaN(dateValue.getTime())) {
              sheetRow[mapping.sheetIndex] = dateValue;
            } else {
              sheetRow[mapping.sheetIndex] = value; // Keep as string if not valid date
            }
          } catch (e) {
            Logger.log(`Date conversion error for column "${mapping.columnName}": ${e.toString()}`);
            sheetRow[mapping.sheetIndex] = value; // Keep original value on error
          }
        } else {
          sheetRow[mapping.sheetIndex] = value;
        }
      }
      
      processedData.push(sheetRow);
    }
    
    // Get or create sheet
    let sheet = ss.getSheetByName(tableName);
    if (!sheet) {
      sheet = ss.insertSheet(tableName);
    }
    
    // Write data to sheet
    if (processedData.length > 0) {
      // First, ensure sheet has enough rows for the data
      const rowsNeeded = processedData.length;
      const currentRows = sheet.getMaxRows();
      
      if (rowsNeeded > currentRows) {
        // Need to add more rows
        sheet.insertRowsAfter(currentRows, rowsNeeded - currentRows);
      } else if (currentRows > rowsNeeded && currentRows > 2) {
        // Have too many rows, delete extras (keep at least rows 1-2, delete row 3 onwards if not needed)
        const rowsToDelete = currentRows - Math.max(rowsNeeded, 2);
        if (rowsToDelete > 0) {
          sheet.deleteRows(Math.max(rowsNeeded, 2) + 1, rowsToDelete);
        }
      }
      
      // Clear existing content in the range we're about to write to
      if (sheet.getLastColumn() > 0) {
        const rowsToClear = Math.min(rowsNeeded, currentRows);
        sheet.getRange(1, 1, rowsToClear, sheet.getLastColumn()).clearContent();
      }
      
      // Write the data
      const range = sheet.getRange(1, 1, processedData.length, processedData[0].length);
      range.setValues(processedData);
      
      Logger.log(`Imported ${processedData.length - 1} rows into "${tableName}"`);
    }
    
    return {
      tableName: tableName,
      rowsImported: processedData.length - 1, // Exclude header
      columnsImported: processedData[0].length
    };
  },

  /**
   * Export current sheet to CSV format with ISO 8601 dates
   */
  csvExportCurrentSheet() {
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
  csvExportAllDataSheets() {
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
  csvExportDataSheetsByTypes(selectedTypes) {
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
  },

  /**
   * Import data sheets from uploaded ZIP file
   * Shows a UI dialog to let users upload a ZIP file and choose which tables to import
   */
  csvImportAllDataSheets() {
    const htmlContent = `
      <html>
        <head>
          <base target="_top">
          <style>
            body {
              font-family: Arial, sans-serif;
              padding: 20px;
            }
            .upload-section {
              margin: 15px 0;
              padding: 15px;
              border: 2px dashed #ccc;
              border-radius: 8px;
              text-align: center;
            }
            .upload-section.dragover {
              border-color: #4CAF50;
              background-color: #f1f8f4;
            }
            .file-input-wrapper {
              margin: 10px 0;
            }
            input[type="file"] {
              display: none;
            }
            .file-select-btn {
              padding: 10px 20px;
              background-color: #2196F3;
              color: white;
              border: none;
              border-radius: 4px;
              cursor: pointer;
              font-size: 14px;
            }
            .file-select-btn:hover {
              background-color: #0b7dda;
            }
            .file-name {
              margin-top: 10px;
              font-style: italic;
              color: #666;
            }
            .checkbox-group {
              margin: 15px 0;
              max-height: 300px;
              overflow-y: auto;
              border: 1px solid #e0e0e0;
              border-radius: 4px;
              padding: 10px;
              display: none;
            }
            .checkbox-group.visible {
              display: block;
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
            .select-all {
              font-weight: bold;
              color: #1a73e8;
              border-bottom: 2px solid #e0e0e0;
              padding-bottom: 10px;
              margin-bottom: 10px;
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
            .import-btn {
              background-color: #4CAF50;
              color: white;
            }
            .import-btn:hover {
              background-color: #45a049;
            }
            .import-btn:disabled {
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
            .message {
              color: #d32f2f;
              font-size: 13px;
              margin-top: 10px;
            }
            .success-message {
              color: #4CAF50;
            }
            .processing {
              display: none;
              color: #2196F3;
              font-weight: bold;
              margin-top: 10px;
            }
          </style>
        </head>
        <body>
          <h3>Import Data from ZIP File</h3>
          
          <div class="upload-section" id="uploadSection">
            <p>Drag and drop a ZIP file here, or click to select</p>
            <div class="file-input-wrapper">
              <input type="file" id="fileInput" accept=".zip" onchange="handleFileSelect(event)">
              <button class="file-select-btn" onclick="document.getElementById('fileInput').click()">
                Select ZIP File
              </button>
            </div>
            <div class="file-name" id="fileName"></div>
          </div>
          
          <div class="checkbox-group" id="checkboxGroup">
            <div class="checkbox-item select-all">
              <input type="checkbox" id="selectAll" onchange="toggleAll(this)">
              <label for="selectAll">Select All</label>
            </div>
            <div id="tableCheckboxes"></div>
          </div>
          
          <div class="message" id="message"></div>
          <div class="processing" id="processing">Analyzing ZIP file...</div>
          
          <div class="button-group">
            <button class="import-btn" id="importBtn" onclick="importSelected()" disabled>Import</button>
            <button class="cancel-btn" onclick="google.script.host.close()">Cancel</button>
          </div>
          
          <script>
            let zipFileBase64 = null;
            let availableTables = [];
            
            // Drag and drop handlers
            const uploadSection = document.getElementById('uploadSection');
            uploadSection.addEventListener('dragover', (e) => {
              e.preventDefault();
              uploadSection.classList.add('dragover');
            });
            
            uploadSection.addEventListener('dragleave', () => {
              uploadSection.classList.remove('dragover');
            });
            
            uploadSection.addEventListener('drop', (e) => {
              e.preventDefault();
              uploadSection.classList.remove('dragover');
              const file = e.dataTransfer.files[0];
              if (file && file.name.endsWith('.zip')) {
                processZipFile(file);
              } else {
                showMessage('Please select a valid ZIP file', false);
              }
            });
            
            function handleFileSelect(event) {
              const file = event.target.files[0];
              if (file) {
                processZipFile(file);
              }
            }
            
            function processZipFile(file) {
              document.getElementById('fileName').textContent = 'Analyzing: ' + file.name;
              document.getElementById('processing').style.display = 'block';
              showMessage('', false);
              
              const reader = new FileReader();
              reader.onload = function(e) {
                // Convert to base64
                const bytes = new Uint8Array(e.target.result);
                let binary = '';
                for (let i = 0; i < bytes.length; i++) {
                  binary += String.fromCharCode(bytes[i]);
                }
                zipFileBase64 = btoa(binary);
                
                // Send to server to analyze ZIP contents
                google.script.run
                  .withSuccessHandler(displayAvailableTables)
                  .withFailureHandler((error) => {
                    showMessage('Error analyzing ZIP: ' + error.message, false);
                    document.getElementById('processing').style.display = 'none';
                    document.getElementById('importBtn').disabled = true;
                  })
                  .analyzeZipContents(zipFileBase64);
              };
              reader.readAsArrayBuffer(file);
            }
            
            function displayAvailableTables(tables) {
              document.getElementById('processing').style.display = 'none';
              availableTables = tables;
              
              if (tables.length === 0) {
                showMessage('No CSV files found in ZIP', false);
                document.getElementById('importBtn').disabled = true;
                return;
              }
              
              const tableCheckboxes = document.getElementById('tableCheckboxes');
              tableCheckboxes.innerHTML = '';
              
              tables.forEach(tableName => {
                const div = document.createElement('div');
                div.className = 'checkbox-item';
                div.innerHTML = \`
                  <input type="checkbox" class="table-checkbox" id="table_\${tableName}" 
                         value="\${tableName}" onchange="updateSelectAll()" checked>
                  <label for="table_\${tableName}">\${tableName}</label>
                \`;
                tableCheckboxes.appendChild(div);
              });
              
              document.getElementById('fileName').textContent = 'ZIP loaded (' + tables.length + ' tables)';
              document.getElementById('checkboxGroup').classList.add('visible');
              document.getElementById('importBtn').disabled = false;
              updateSelectAll();
              showMessage(\`Found \${tables.length} table(s) ready to import\`, true);
            }
            
            function toggleAll(checkbox) {
              const checkboxes = document.querySelectorAll('.table-checkbox');
              checkboxes.forEach(cb => cb.checked = checkbox.checked);
            }
            
            function updateSelectAll() {
              const checkboxes = document.querySelectorAll('.table-checkbox');
              const selectAll = document.getElementById('selectAll');
              const allChecked = Array.from(checkboxes).every(cb => cb.checked);
              selectAll.checked = allChecked;
            }
            
            function showMessage(msg, isSuccess) {
              const messageEl = document.getElementById('message');
              messageEl.textContent = msg;
              if (isSuccess) {
                messageEl.classList.add('success-message');
              } else {
                messageEl.classList.remove('success-message');
              }
            }
            
            function importSelected() {
              const checkboxes = document.querySelectorAll('.table-checkbox:checked');
              const selectedTables = Array.from(checkboxes).map(cb => cb.value);
              
              if (selectedTables.length === 0) {
                showMessage('Please select at least one table to import', false);
                return;
              }
              
              // Disable buttons and show processing
              document.getElementById('importBtn').disabled = true;
              document.getElementById('processing').textContent = 'Importing tables...';
              document.getElementById('processing').style.display = 'block';
              showMessage('', false);
              
              // Call the server-side function with ZIP data and selected tables
              google.script.run
                .withSuccessHandler((result) => {
                  let msg = \`Successfully imported \${result.successCount} of \${result.totalCount} tables\`;
                  if (result.errors.length > 0) {
                    msg += '\\nErrors: ' + result.errors.join('; ');
                  }
                  showMessage(msg, result.successCount > 0);
                  document.getElementById('processing').style.display = 'none';
                  if (result.successCount > 0) {
                    setTimeout(() => { google.script.host.close(); }, 3000);
                  } else {
                    document.getElementById('importBtn').disabled = false;
                  }
                })
                .withFailureHandler((error) => {
                  showMessage('Import error: ' + error.message, false);
                  document.getElementById('processing').style.display = 'none';
                  document.getElementById('importBtn').disabled = false;
                })
                .csvImportOfDataSheetsBySelectedTypes(zipFileBase64, selectedTables);
            }
          </script>
        </body>
      </html>
    `;

    const html = HtmlService.createHtmlOutput(htmlContent)
      .setWidth(500)
      .setHeight(550);

    SpreadsheetApp.getUi().showModalDialog(html, "Import Data Sheets");
  },

  /**
   * Analyze ZIP file contents and return list of CSV table names
   * @param {string} base64ZipData - Base64 encoded ZIP file data
   * @returns {string[]} Array of table names found in ZIP
   */
  analyzeZipContents(base64ZipData) {
    try {
      const zipBlob = Utilities.newBlob(
        Utilities.base64Decode(base64ZipData),
        'application/zip',
        'upload.zip'
      );
      
      const unzippedBlobs = Utilities.unzip(zipBlob);
      const tableNames = [];
      
      for (const blob of unzippedBlobs) {
        const filename = blob.getName();
        if (filename.endsWith('.csv')) {
          const tableName = filename.replace('.csv', '');
          tableNames.push(tableName);
        }
      }
      
      return tableNames;
    } catch (error) {
      Logger.log('Error analyzing ZIP: ' + error.toString());
      throw new Error('Failed to analyze ZIP file: ' + error.message);
    }
  },

  /**
   * Import data sheets from ZIP file data
   * @param {string} base64ZipData - Base64 encoded ZIP file data
   * @param {string[]} selectedTables - Array of table names to import
   * @returns {Object} Import result summary
   */
  csvImportDataSheetsByTypes(base64ZipData, selectedTables) {
    const results = {
      successCount: 0,
      totalCount: selectedTables.length,
      errors: []
    };

    try {
      // Decode and unzip the file
      const zipBlob = Utilities.newBlob(
        Utilities.base64Decode(base64ZipData),
        'application/zip',
        'upload.zip'
      );
      
      const unzippedBlobs = Utilities.unzip(zipBlob);
      
      // Create a map of filename to blob
      const fileMap = {};
      for (const blob of unzippedBlobs) {
        fileMap[blob.getName()] = blob;
      }
      
      // Import selected tables
      for (const tableName of selectedTables) {
        const filename = tableName + '.csv';
        const blob = fileMap[filename];
        
        if (!blob) {
          const errorMsg = `File not found: ${filename}`;
          results.errors.push(errorMsg);
          Logger.log(errorMsg);
          continue;
        }
        
        try {
          const csvContent = blob.getDataAsString();
          const result = this.csvImportTableData(tableName, csvContent);
          results.successCount++;
          Logger.log(`Successfully imported "${tableName}": ${result.rowsImported} rows`);
        } catch (error) {
          const errorMsg = `Failed to import "${tableName}": ${error.message}`;
          results.errors.push(errorMsg);
          Logger.log(errorMsg);
        }
      }
    } catch (error) {
      Logger.log('Error processing ZIP: ' + error.toString());
      throw new Error('Failed to process ZIP file: ' + error.message);
    }

    return results;
  }
};

/**
 * Global function to export data sheets by selected types
 * This is a wrapper that can be called from google.script.run
 * @param {string[]} selectedTypes - Array of table type strings to export
 */
function csvExportOfDataSheetsBySelectedTypes(selectedTypes) {
  exportImport.csvExportDataSheetsByTypes(selectedTypes);
}

/**
 * Global function to import data sheets from ZIP file
 * This is a wrapper that can be called from google.script.run
 * @param {string} base64ZipData - Base64 encoded ZIP file data
 * @param {string[]} selectedTables - Array of table names to import
 */
function csvImportOfDataSheetsBySelectedTypes(base64ZipData, selectedTables) {
  return exportImport.csvImportDataSheetsByTypes(base64ZipData, selectedTables);
}

/**
 * Global function to analyze ZIP contents
 * This is a wrapper that can be called from google.script.run
 * @param {string} base64ZipData - Base64 encoded ZIP file data
 * @returns {string[]} Array of table names found in ZIP
 */
function analyzeZipContents(base64ZipData) {
  return exportImport.analyzeZipContents(base64ZipData);
}
