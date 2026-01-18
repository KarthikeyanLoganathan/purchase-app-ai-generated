# Header-Based Column Mapping Implementation

## Overview
Updated backend Google Apps Script code to use actual sheet column headers for reading/writing data instead of relying on hardcoded `TABLE_META_INFO.COLUMN_INDICES`. This makes the code resilient to column reordering in Google Sheets.

## Changes Made

### 1. New Utility Functions in utils.js

#### `getSheetColumnMap(sheet, tableName)`
- Reads the first row of a sheet as headers
- Creates a mapping: `{ columnName: columnIndex }`
- Optionally validates against TABLE_DEFINITIONS
- Returns column map for flexible column access

#### `buildRowDataFromRecord(record, columnNames, columnMap, tableName)`
- Builds row data array from record object using column map
- Handles date column conversion
- Returns array aligned with actual sheet column order
- Used for writing data to sheets

### 2. Updated Files

#### deltaSync.js
- **upsertRecords()**: Now uses `getSheetColumnMap()` and `buildRowDataFromRecord()`
- **deleteRecords()**: Uses column map to find key column index
- **batchGetRecordsByKeys()**: Uses column map for reading records

#### dataReaders.js
- **readManufacturers()**: Uses column map instead of COLUMN_INDICES
- **readVendors()**: Uses column map instead of COLUMN_INDICES
- **readMaterials()**: Uses column map instead of COLUMN_INDICES
- **readManufacturerMaterials()**: Uses column map instead of COLUMN_INDICES
- **readVendorPriceList()**: Uses column map instead of COLUMN_INDICES

#### maintainManufacturerModels.js
- **saveManufacturerModelsData()**: Uses column map for delete and insert operations
- Uses `buildRowDataFromRecord()` for creating row data

#### changeLogUtils.js
- **initializeChangeLogFromDataSheets()**: Uses column map for reading key columns
- **prepareCondensedChangeLogFromChangeLog()**: Uses column map for reading change log

### 3. Files NOT Modified (and why)

#### setup.js
- Creates and maintains sheet structure with headers
- Only writes headers based on TABLE_DEFINITIONS (correct behavior)
- No data read/write operations that depend on column order

#### maintainVendorPriceLists.js
- Uses `deltaSync.upsertRecords()` which is already updated
- Layout constants are for UI sheet positions (not data tables)

#### utils.js (lookup/validation functions)
- `applyLookupFormulas()`: Creates formulas based on table structure (correct)
- `createDataValidationForGivenRange()`: Sets up validation rules (correct)
- These functions define the structure, not read/write data

## Benefits

### 1. Resilience to Column Reordering
Users can now reorder columns in Google Sheets without breaking the sync logic. The code reads actual headers and adapts to column positions.

### 2. Easier Maintenance
Adding new columns or removing old ones is now safer. The column map approach is self-documenting.

### 3. Consistency with Frontend
Frontend CSV import already uses header-based parsing. Backend now follows the same pattern.

## Example Usage

### Before (Hardcoded Indices)
```javascript
const colIdx = TABLE_META_INFO[tableName].COLUMN_INDICES;
const uuid = sheetData[i][colIdx.uuid];
const name = sheetData[i][colIdx.name];
```

### After (Header-Based)
```javascript
const columnMap = utils.getSheetColumnMap(sheet, tableName);
const uuid = sheetData[i][columnMap.uuid];
const name = sheetData[i][columnMap.name];
```

### Writing Data Before
```javascript
const rowData = tableMetaInfo.COLUMN_NAMES.map((colName) => {
    return record[colName] || "";
});
sheet.getRange(row, 1, 1, tableMetaInfo.COLUMN_COUNT).setValues([rowData]);
```

### Writing Data After
```javascript
const columnMap = utils.getSheetColumnMap(sheet, tableName);
const rowData = utils.buildRowDataFromRecord(record, tableMetaInfo.COLUMN_NAMES, columnMap, tableName);
const numCols = Math.max(...Object.values(columnMap)) + 1;
sheet.getRange(row, 1, 1, numCols).setValues([rowData]);
```

## Testing Recommendations

1. **Test column reordering**: 
   - Manually reorder columns in a data sheet
   - Run delta sync from mobile app
   - Verify data is written to correct columns

2. **Test new sheet setup**:
   - Delete a sheet and run setup again
   - Verify columns are created in correct order

3. **Test data reading**:
   - Prepare/save data in maintainManufacturerModels and maintainVendorPriceLists
   - Verify data is read and written correctly

4. **Test change log**:
   - Make changes in mobile app
   - Verify change log captures correct data
   - Verify delta sync applies changes correctly

## Migration Notes

- Existing sheets with standard column order will work without changes
- Users who already reordered columns should see improved reliability
- No data migration required
- All changes are backward compatible

## Future Enhancements

Consider updating these files in future:
- `consistencyChecks.js` - Still uses COLUMN_INDICES for validation checks
- `exportCSV.js` - Could benefit from header-based approach
- `maintainManufacturerModelData.js` - Similar pattern to maintainManufacturerModels.js
