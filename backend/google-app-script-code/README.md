# Google Apps Script Backend - Purchase App

Backend code for the Flutter Purchase App, written in Google Apps Script. This provides the server-side sync functionality using Google Sheets as the database.

## Overview

This backend implements:
- **Delta sync** between Flutter app and Google Sheets with change log tracking
- **RESTful API endpoints** for data synchronization (pull/push operations)
- **Comprehensive table schema** with 16 tables including master data, transaction data, configuration data, and logs
- **Data maintenance utilities** for manufacturer materials, vendor price lists, and model data
- **Foreign key consistency** validation and automated cleanup
- **CSV/ZIP export** functionality for data portability
- **Namespace-based code organization** for modularity and maintainability
- **Web app deployment** automation

## Project Structure

```
google-app-script-code/
├── Code.js                             # Legacy monolithic file (deprecated)
├── constants.js                        # Global constants and change modes
├── tableMetadata.js                    # Comprehensive table metadata (16 tables, columns, data types, foreign keys)
├── config.js                           # config namespace - Configuration management
├── setup.js                            # setup namespace - Sheet setup and initialization
├── utils.js                            # utils namespace - Utility functions (UUID, date, sheet operations)
├── webService.js                       # doGet/doPost web endpoints (login, delta_pull, delta_push)
├── webSecurity.js                      # webSecurity namespace - Request validation and authentication
├── deltaSync.js                        # deltaSync namespace - Sync logic (upsert, delete, batch operations)
├── changeLogUtils.js                   # changeLog namespace - Change log management
├── dataReaders.js                      # dataReaders namespace - Data reading with filter support
├── cleanup.js                          # cleanup namespace - Data cleanup utilities
├── consistencyChecks.js                # consistencyChecks namespace - Foreign key validation and cleanup
├── exportCSV.js                        # csvExport namespace - CSV/ZIP export functionality
├── deployer.js                         # deployer namespace - Web app deployment automation
├── maintainManufacturerModels.js       # maintainManufacturerModelNames namespace - Model names maintenance
├── maintainManufacturerModelData.js    # maintainManufacturerModelData namespace - MRP/lot size maintenance
├── maintainVendorPriceLists.js         # maintainVendorPriceLists namespace - Vendor price list maintenance
├── sheetEventHandlers.js               # onEdit, onOpen event triggers
├── z-test.js                           # Test functions
├── globals.d.ts                        # TypeScript definitions for VSCode IntelliSense
├── jsconfig.json                       # VSCode JavaScript configuration
├── package.json                        # npm dependencies and scripts
├── .clasp.json.example                 # Example clasp configuration
├── .claspignore                        # Files to exclude from clasp push
└── README.md                           # This file
```

## Database Schema

The backend manages **16 tables** organized into 4 categories:

### Configuration Data Tables (101-102)
- **unit_of_measures** - Units of measurement (kg, pcs, ltr, etc.)
- **currencies** - Currency definitions (USD, EUR, INR, etc.)

### Master Data Tables (201-251)
- **manufacturers** - Manufacturer master data
- **vendors** - Vendor master data  
- **materials** - Material master data
- **manufacturer_materials** - Manufacturer-material relationships with models and pricing
- **vendor_price_lists** - Vendor pricing for manufacturer materials
- **projects** - Project master data

### Transaction Data Tables (301-322)
- **purchase_orders** - Purchase order headers
- **purchase_order_items** - Purchase order line items
- **purchase_order_payments** - Purchase order payment records
- **baskets** - Shopping baskets
- **basket_items** - Shopping basket items
- **quotations** - Quotation headers
- **quotation_items** - Quotation line items

### Log Tables
- **change_log** - Tracks all changes for delta sync
- **condensed_change_log** - Optimized change log for efficient sync

All table metadata is defined in [tableMetadata.js](tableMetadata.js) with complete column definitions, data types, foreign key relationships, and lookup formulas.

## Code Organization

The codebase uses a **namespace pattern** for better modularity and organization:

### Namespaces

- **`config`** - Configuration value retrieval
  - `config.getConfigValue(name)` - Get configuration value from config sheet

- **`setup`** - Sheet setup and initialization
  - `setup.setupDataTableSheets()` - Initialize all data sheets
  - `setup.setupDataTableSheet(tableName, doLogging)` - Setup individual table/sheet
  - `setup.setupDataTableSheetForCurrentSheet()` - Setup currently active sheet
  - `setup.setupStatisticsSheet()` - Setup statistics dashboard sheet

- **`utils`** - Utility functions
  - `utils.UUID()` - Generate UUID
  - `utils.fillUUID()` - Fill missing UUIDs in active sheet
  - `utils.normalizeTextsInSelectedColumn()` - Normalize text in selected column
  - `utils.getEpochTimeMilliseconds(input, defaultValue)` - Convert to epoch time
  - `utils.isDateColumn(tableName, columnName)` - Check if column is a date
  - `utils.autoResizeSheetColumns(sheet)` - Auto-resize columns
  - `utils.applyNumericFormatting(sheet, tableName)` - Apply numeric formatting
  - `utils.applyLookupFormulas(sheet, tableName)` - Apply lookup formulas
  - `utils.createDataValidationForGivenRange(...)` - Create data validation dropdown
  - `utils.removeProtectionsFromSheet(sheet)` - Remove sheet protections
  - `utils.getWebAppUrl()` - Get deployed web app URL
  - `utils.deleteRowsFromSheetGivenStartRow(sheet, startRow)` - Delete rows from sheet

- **`cleanup`** - Data cleanup operations
  - `cleanup.cleanupSheet(sheetName)` - Clear data from specific sheet
  - `cleanup.cleanupCurrentSheet()` - Cleanup currently active sheet
  - `cleanup.cleanupTransactionDataSheets()` - Cleanup all transaction data sheets
  - `cleanup.cleanupLogDataSheets()` - Cleanup all log sheets

- **`consistencyChecks`** - Foreign key consistency validation and cleanup
  - `consistencyChecks.displayRecordCountStatistics()` - Display record count statistics for all tables
  - `consistencyChecks.generateConsistencyReport()` - Generate consistency validation report (simulate mode)
  - `consistencyChecks.performConsistencyCleanup()` - Perform consistency cleanup (actually delete invalid records)
  - `consistencyChecks.checkNullUUIDs(tableName)` - Check for null/empty UUIDs in a table
  - `consistencyChecks.loadTargetUUIDs(tableName)` - Load all valid UUIDs from a target table
  - `consistencyChecks.checkAndCleanTable(tableName, simulate)` - Check and optionally clean a specific table
  - `consistencyChecks.checkAndCleanAllTables(simulate)` - Check and optionally clean all tables with foreign keys
  - `consistencyChecks.deleteInvalidRecords(sheet, tableName, invalidRecords, simulate)` - Delete invalid records
  - `consistencyChecks.logDeletions(tableName, invalidRecords)` - Log deletions to change log

- **`dataReaders`** - Data reading functions with optional filtering
  - `dataReaders.readManufacturers(filter)` - Read manufacturers
  - `dataReaders.readVendors(filter)` - Read vendors
  - `dataReaders.readMaterials(filter)` - Read materials
  - `dataReaders.readManufacturerMaterials(manufacturersMap, materialsMap, filter)` - Read manufacturer materials
  - `dataReaders.readVendorPriceList(manufacturersMap, materialsMap, manufacturerMaterialsMap, filter)` - Read vendor price lists

- **`deltaSync`** - Delta synchronization
  - `deltaSync.upsertRecords(tableName, records)` - Insert or update records
  - `deltaSync.deleteRecords(tableName, deletions)` - Delete records
  - `deltaSync.applyDeltaChangesBatch(log, tableRecords)` - Apply batch of changes
  - `deltaSync.fetchTableRecordsForChanges(log)` - Fetch records based on change log
  - `deltaSync.batchGetRecordsByUuids(sheet, tableName, uuids)` - Get multiple records by UUID

- **`changeLog`** - Change log management
  - `changeLog.initializeChangeLogFromDataSheets()` - Initialize change log from all data
  - `changeLog.logChange(tableName, key, changeMode, updatedAt)` - Log single change
  - `changeLog.logChanges(tableName, keys, changeMode, updatedAt)` - Log multiple changes (batch)
  - `changeLog.prepareCondensedChangeLogFromChangeLog(since)` - Prepare condensed change log
  - `changeLog.writeCondensedChangeLog(since)` - Write condensed log to sheet
  - `changeLog.writeCondensedChangeLogForAllData()` - Write condensed log for all data
  - `changeLog.readCondensedChangeLog(offset, limit)` - Read condensed log with pagination

- **`maintainManufacturerModelNames`** - Manufacturer model names maintenance
  - `maintainManufacturerModelNames.setupSheet()` - Setup "saveData" input sheet
  - `maintainManufacturerModelNames.prepareData()` - Prepare/load data for editing
  - `maintainManufacturerModelNames.saveData()` - Save changes to manufacturer_materials table
  - `maintainManufacturerModelNames.clearData()` - Clear input data rows
  - `maintainManufacturerModelNames.protectSheet()` - Protect sheet regions
  - `maintainManufacturerModelNames.onEdit(range)` - Handle checkbox button clicks
  - `maintainManufacturerModelNames.LAYOUT` - Layout constants (button positions, columns, etc.)

- **`maintainManufacturerModelData`** - Manufacturer model MRP/lot size maintenance
  - `maintainManufacturerModelData.setupSheet()` - Setup "MaintainManufacturerMaterialModelData" input sheet
  - `maintainManufacturerModelData.prepareData()` - Prepare/load data for editing
  - `maintainManufacturerModelData.saveData()` - Save MRP and lot size changes
  - `maintainManufacturerModelData.clearData()` - Clear input data rows
  - `maintainManufacturerModelData.protectSheet()` - Protect sheet regions
  - `maintainManufacturerModelData.onEdit(range)` - Handle checkbox button clicks
  - `maintainManufacturerModelData.LAYOUT` - Layout constants (button positions, columns, etc.)

- **`maintainVendorPriceLists`** - Vendor price list maintenance
  - `maintainVendorPriceLists.setupSheet()` - Setup "MaintainVendorPrices" input sheet
  - `maintainVendorPriceLists.prepareData()` - Prepare/load data for editing
  - `maintainVendorPriceLists.saveData()` - Save vendor price changes
  - `maintainVendorPriceLists.clearData()` - Clear input data rows
  - `maintainVendorPriceLists.onEdit(range)` - Handle checkbox button clicks
  - `maintainVendorPriceLists.LAYOUT` - Layout constants

- **`webSecurity`** - Request validation and security
  - `webSecurity.validateSecretCode(providedCode)` - Validate secret code against configuration

- **`csvExport`** - CSV/ZIP export functionality
  - `csvExport.exportCurrentSheet()` - Export currently active sheet to CSV file
  - `csvExport.exportAllDataSheets()` - Export all data sheets to ZIP file

- **`deployer`** - Web app deployment automation
  - `deployer.deployWebApp()` - Create new web app deployment with version description

### Global Functions (Non-namespaced)

These functions are available globally for menu integration and web endpoints:

- `onOpen()` - Creates custom "Purchase App" menu (in [sheetEventHandlers.js](sheetEventHandlers.js))
- `onEdit(e)` - Handles checkbox button clicks in maintenance sheets (in [sheetEventHandlers.js](sheetEventHandlers.js))
- `doPost(e)` - Web service POST endpoint for delta sync (in [webService.js](webService.js))
- `doGet(e)` - Web service GET endpoint (in [webService.js](webService.js))

### Usage Examples

```javascript
// Configuration
const appCode = config.getConfigValue("APP_CODE");

// UUID generation
const newId = utils.UUID();

// Data reading with filters
const manufacturers = dataReaders.readManufacturers({ id: "M001" });

// Delta sync
const upserted = deltaSync.upsertRecords("materials", records);

// Change logging
changeLog.logChange("materials", uuid, "I", new Date());

// Cleanup
cleanup.cleanupSheet("manufacturers");

// Consistency checks
// Check all tables and get a report (simulate mode - doesn't delete)
const report = consistencyChecks.generateConsistencyReport();

// Check and clean all tables (actually delete invalid records)
consistencyChecks.performConsistencyCleanup();

// Check for null UUIDs in a table
const nullCheck = consistencyChecks.checkNullUUIDs("basket_items");

// Setup
setup.setupDataTableSheet("vendors", true);

// Maintenance sheet setup
maintainManufacturerModelNames.setupSheet();
maintainManufacturerModelData.setupSheet();

// CSV Export
csvExport.exportCurrentSheet();
csvExport.exportAllDataSheets();

// Web app deployment
deployer.deployWebApp();
```

## Prerequisites

- Node.js and npm installed
- Google account with access to Google Apps Script
- VS Code (recommended) or any code editor

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

This installs:
- `@google/clasp` - Command-line tool for Apps Script
- `@types/google-apps-script` - TypeScript definitions for IntelliSense

### 2. Login to Google Apps Script

First time only:

```bash
npm run login
```

This opens a browser window to authenticate with your Google account.

### 3. Connect to Your Apps Script Project

You have two options:

#### Option A: Connect to Existing Project

1. Open your Google Apps Script project in browser
2. Get the Script ID from the URL: `https://script.google.com/home/projects/{SCRIPT_ID}/edit`
3. Copy the example configuration:

```bash
cp .clasp.json.example .clasp.json
```

4. Edit `.clasp.json` and replace `YOUR_SCRIPT_ID_HERE` with your actual Script ID:

```json
{
  "scriptId": "1a2b3c4d5e6f7g8h9i0j_actual_script_id",
  "rootDir": "."
}
```

**Note:** `.clasp.json` is gitignored and won't be committed to the repository.

#### Option B: Create New Project

```bash
npm run create
```

This creates a new Apps Script project linked to a Google Sheet.

### 4. Push Code to Google Apps Script

```bash
npm run push
```

This uploads all `.js` files to your Apps Script project. Clasp automatically converts them to `.gs` format when pushing to Google Apps Script.

## Usage

### Available npm Scripts

| Command | Description |
|---------|-------------|
| `npm run login` | Authenticate with Google (first time only) |
| `npm run push` | Upload all local files to Apps Script |
| `npm run pull` | Download files from Apps Script to local |
| `npm run open` | Open the Apps Script project in browser |
| `npm run create` | Create new Apps Script project |

### Development Workflow

1. **Edit Code Locally** - Use VS Code with IntelliSense support
2. **Push to Apps Script** - Run `npm run push`
3. **Test in Google Sheets** - Open your spreadsheet and test functionality
4. **Pull Changes** - If you made edits in web editor, run `npm run pull`

### VSCode IntelliSense

The project includes TypeScript definitions for full IntelliSense support:

- **Google Apps Script APIs** - Auto-complete for SpreadsheetApp, etc.
- **Namespace Objects** - Auto-complete for config, utils, cleanup, dataReaders, deltaSync, changeLog, etc.
- **Custom Functions** - Jump to definition across files (Cmd+Click)
- **Global Constants** - All constants from `constants.js` and `tableMetadata.js` are recognized

The `globals.d.ts` file declares only truly global functions (like `setup()`, `doPost()`, `onOpen()`). Namespace objects are automatically inferred by TypeScript from their const declarations in the JavaScript files.

Reload VS Code window if IntelliSense doesn't work: `Cmd+Shift+P` → "Developer: Reload Window"

## File Management

### Files to Push

All `.js` files are automatically pushed to Google Apps Script and converted to `.gs` format.

### Files Ignored (`.claspignore`)

The following files are NOT uploaded to Apps Script:
- `node_modules/`
- `package.json`, `package-lock.json`
- `jsconfig.json`, `globals.d.ts`
- `.git/`, `.gitignore`
- `README.md`

## Google Sheets Setup

### First Time Setup

1. Create a new Google Sheet for your Purchase App
2. Open **Extensions → Apps Script**
3. Note the Script ID from the URL
4. Update `.clasp.json` with this Script ID
5. Run `npm run push`
6. In Google Sheets: **Purchase App → Setup / Update Schema**

### Menu Functions

After setup, the Google Sheet has a custom menu:

**Purchase App Menu:**
- **Fill UUID** - Generate UUIDs for records missing them
- **Normalize Texts in Selected Column** - Normalize text formatting in selected column
- **Display Record Statistics** - Show record count statistics for all tables
- **Do Consistency Checks** - Validate foreign key relationships (report only, doesn't delete)
- **Perform Consistency Cleanup** - Find and remove records with invalid foreign keys
- **Export Current Sheet to CSV** - Download current sheet as CSV file
- **Export All Data Sheets to ZIP** - Download all data sheets as ZIP archive
- **Cleanup Current Sheet** - Remove data rows from current sheet
- **Cleanup Transaction Data Sheets** - Clear all transaction data tables
- **Cleanup Log Data Sheets** - Clear all log tables
- **Initialize Change Log from Data Sheets** - Create change log from existing data
- **Write Condensed Change Log** - Generate condensed change log for all data
- **Setup / Update Schema** - Create or update all table schemas
- **Setup / Update Schema for Current Sheet** - Update schema for currently active sheet
- **Setup Statistics Sheet** - Create statistics dashboard sheet
- **Setup Maintain Manufacturer Material Models - Input Sheet** - Create "saveData" sheet for managing model names
- **Setup Maintain Manufacturer Material Model Data - Input Sheet** - Create sheet for managing MRP/lot sizes
- **Setup Maintain Vendor Price Lists - Input Sheet** - Create sheet for vendor pricing
- **Deploy Web App** - Create new web app deployment

### Maintenance Sheets

The maintenance sheets use interactive checkbox buttons:

**"saveData" Sheet** (Manufacturer Material Model Names):
- Manufacturer dropdown to select manufacturer
- ⚡ **Prepare** - Load existing models for the selected manufacturer
- 💾 **Save** - Save new/modified model names to database
- 🗑️ **Clear** - Clear all input data

**"MaintainManufacturerMaterialModelData" Sheet** (MRP/Lot Size):
- Manufacturer dropdown to select manufacturer
- ⚡ **Prepare** - Load existing MRP and lot size data
- 💾 **Save** - Save updated MRP and lot size values
- 🗑️ **Clear** - Clear all input data

**"MaintainVendorPrices" Sheet** (Vendor Price Lists):
- Vendor, Manufacturer, and Material dropdowns
- ⚡ **Prepare** - Load vendor price data
- 💾 **Save** - Save updated vendor prices
- 🗑️ **Clear** - Clear all input data

## API Endpoints

The backend exposes web service endpoints for the Flutter app:

### POST /doPost

**Operations:**
- `login` - Validate credentials/secret code
- `delta_pull` - Download changes from Google Sheets (with pagination)
- `delta_push` - Upload changes to Google Sheets

**Login Request:**
```json
{
  "secret": "your-secret-code",
  "operation": "login"
}
```

**Delta Pull Request:**
```json
{
  "secret": "your-secret-code",
  "operation": "delta_pull",
  "since": "2024-01-01T00:00:00Z",
  "offset": 0,
  "limit": 200
}
```

**Delta Push Request:**
```json
{
  "secret": "your-secret-code",
  "operation": "delta_push",
  "log": [
    {"table_identifier_index": 201, "key": "uuid-123", "change_mode": "I", "updated_at": 1234567890000}
  ],
  "tableRecords": {
    "201": [
      {"uuid": "uuid-123", "id": "M001", "name": "Manufacturer Name", ...}
    ]
  }
}
```

**Delta Pull Response:**
```json
{
  "success": true,
  "log": [...],
  "totalRecords": 500,
  "tableRecords": {...}
}
```

## Configuration

### Secret Code

Set your secret code in Google Sheets:
1. Create a sheet named `config`
2. Add a header row: `name | value`
3. Add configuration row: `APP_CODE | your-secret-value`

The secret code is used to authenticate API requests from the Flutter app.

### Table Metadata

All table schemas are defined in [tableMetadata.js](tableMetadata.js):
- **16 data tables** across 4 categories (configuration, master, transaction, log)
- **TABLE_NAMES_TO_INDICES** - Map table names to numeric identifiers (101-322)
- **TABLE_INDICES_TO_NAMES** - Reverse mapping from identifiers to names
- **DATA_TYPES** - Comprehensive data type definitions (UUID, INTEGER, AMOUNT, CURRENCY, etc.)
- **TABLE_TYPES** - Table categorization (METADATA, CONFIGURATION_DATA, MASTER_DATA, TRANSACTION_DATA, LOG)
- **TABLE_DEFINITIONS** - Complete schema for each table:
  - Column names and data types
  - Key column (primary key)
  - Lookup formulas for foreign key relationships (VLOOKUP)
  - Foreign key relationships with target tables and columns
  - Numeric formatting rules
- All metadata is deeply frozen using `Object.freeze()` for complete immutability

### Layout Constants

Maintenance sheets use frozen layout constants for consistent UI:

**`maintainManufacturerModelNames.LAYOUT`:**
- `SHEET: "saveData"` - Sheet name
- `TITLE_ROW: 1` - Title row position
- `INPUT_MANUFACTURER_ROW: 2` - Manufacturer dropdown row
- `BUTTONS_ROW: 3` - Button (checkbox) row
- `HEADER_ROW: 4` - Column header row
- `DATA_START_ROW: 5` - First data row
- `MATERIAL_COLUMN: 1`, `UNIT_COLUMN: 2` - Data columns
- `FIRST_MODEL_COLUMN: 3`, `NUMBER_OF_MODELS: 10` - Model columns (3-12)
- Button column positions: `PREPARE`, `SAVE`, `CLEAR` checkboxes

**`maintainManufacturerModelData.LAYOUT`:**
- `SHEET: "MaintainManufacturerMaterialModelData"` - Sheet name
- `MRP_COLUMN: 1`, `LOT_SIZE_COLUMN: 2` - Input columns
- `MATERIAL_COLUMN: 3`, `MODEL_COLUMN: 4`, `UNIT_COLUMN: 5`, `CURRENCY_COLUMN: 6` - Display columns
- Similar button and row structure as model names sheet

**`maintainVendorPriceLists.LAYOUT`:**
- `SHEET: "MaintainVendorPrices"` - Sheet name
- Vendor, Manufacturer, Material input rows
- Similar structure to other maintenance sheets

## Troubleshooting

### Push Fails

**Error:** `Push failed. Errors:`

**Solution:** 
- Check if you're logged in: `npm run login`
- Verify Script ID in `.clasp.json`
- Ensure you have edit permissions on the Apps Script project

### IntelliSense Not Working

**Solution:**
1. Reload VS Code: `Cmd+Shift+P` → "Developer: Reload Window"
2. Verify `jsconfig.json` exists
3. Check TypeScript version: Should auto-detect types

### Authentication Issues

**Error:** `User has not enabled the Apps Script API`

**Solution:**
1. Visit: https://script.google.com/home/usersettings
2. Enable "Google Apps Script API"
3. Try login again

## Best Practices

### Code Organization

- **Namespace pattern** - Functions are organized into namespace objects (config, utils, cleanup, etc.)
- **One function per purpose** - Keep functions focused and modular
- **Use namespaces** - Access functions via their namespace (e.g., `utils.UUID()`, `config.getConfigValue()`)
- **Use constants** - Define in `constants.js` or `tableMetadata.js`
- **Layout constants** - Use frozen objects for UI layouts (prevents accidental changes)
- **Immutable metadata** - All metadata objects are frozen to prevent modification
- **JSDoc comments** - Add type annotations for better IntelliSense
- **Error handling** - Use try-catch and log errors appropriately
- **Filter parameters** - Data readers support optional filter objects for efficient queries
- **Internal method calls** - Within namespace objects, use `this.methodName()` to call other methods

### Namespace Best Practices

**DO:**
```javascript
// Call namespace methods with the namespace prefix
const uuid = utils.UUID();
const manufacturers = dataReaders.readManufacturers();
cleanup.cleanupSheet("materials");
```

**Within namespace objects:**
```javascript
const myNamespace = {
  methodA() {
    // Call other methods in same namespace using 'this'
    this.methodB();
  },
  methodB() {
    // Can call methods from other namespaces directly
    const uuid = utils.UUID();
  }
};
```

### Development Workflow

- **Push frequently** - Small, incremental changes
- **Test before deploy** - Always test in Google Sheets after pushing
- **Pull before edit** - If using web editor, pull changes first
- **Use version control** - Git commit before pushing to Apps Script
- **Test API endpoints** - Use Postman or similar tools to test web service endpoints
- **Monitor logs** - Check Apps Script execution logs for errors

### Data Consistency

- **Run consistency checks** regularly to validate foreign key relationships
- **Initialize change log** after bulk data imports
- **Use cleanup functions** to clear test data
- **Export data** regularly as backup (CSV/ZIP export)

## Delta Sync Architecture

The backend implements efficient delta synchronization:

1. **Change Log** - Tracks all INSERT, UPDATE, DELETE operations
2. **Condensed Change Log** - Optimized view for sync operations (removes redundant entries)
3. **Pagination Support** - Pull changes in batches (default 200 records per request)
4. **Batch Operations** - Efficient batch upsert and delete operations
5. **Timestamp-based Sync** - Only sync changes after a given timestamp

### Sync Flow

**Pull (Download from Server):**
```
Client → Request with 'since' timestamp → Server
Server → Generate condensed change log → Fetch affected records
Server → Return log + records (paginated) → Client
Client → Apply changes to local database
```

**Push (Upload to Server):**
```
Client → Send change log + records → Server
Server → Apply batch operations (upsert/delete)
Server → Update change log → Client
Client → Mark changes as synced
```

## Links

- [Google Apps Script Documentation](https://developers.google.com/apps-script)
- [clasp Documentation](https://github.com/google/clasp)
- [TypeScript Definitions](https://www.npmjs.com/package/@types/google-apps-script)

## License

ISC
