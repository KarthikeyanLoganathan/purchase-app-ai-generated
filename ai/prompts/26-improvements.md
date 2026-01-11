SetupGoogleSheetScreen _uploadDataToGoogleSheets() to be refactored
- input:
  - sheetId
  - currentGoogleUser
- logic:
  - current upload logic


In CommonOverFlowMenu.
- add menu item "Upload to Google Sheet"
    - enabled only if SettingsManager.googleSheetId.value is valid and not empty
    - on click, shows a popup
        - checks if SettingsManager.googleSheetId.value is valid and not empty
        - offer Google Sign In option (like implemented in SetupGoogleSheetScreen)
        - Provide upload button.  
          - on click invoke GoogleSheetUploadService.uploadDataToGoogleSheets
        - needless to say, click outside cancels the popup


rename class GoogleSheetUploadService, GoogleSheetInterfaceService

In GoogleSheetInterfaceService, provide a method readStatistics(sheetid)
- input:
  - sheetId
  - currentGoogleUser
- result
  - Map<String, number>
- Logic
  - read "statistics" sheet of the given sheetId - columns 1, 2, from row 2 onwards - where first column is not empty


In SetupGoogleSheetScreen, in Step 5, after "Setup Sheets" button, provide another button "Data Statistics in Sheet", invokes GoogleSheetInterfaceService.readStatistics
- provides a popup displaying plain text of Map<string, number> as one line per row 


UploadToGoogleSheetDialog should have toggle google signin/signout like we have in SetupGoogleSheetScreen



In GoogleSheetInterfaceService, provide a function importDataFromGoogleSheet
- For each tableName in TableNames.allDataTables
    - get tableColumnNames using DatabaseHelper.getTableColumnNames(tableName)
    - sheet = get Google Sheet Worksheet by Name = tableName
    - get sheetColumnNames = column values from first row
    - Delete tableName (in SQLite clear records of table tableName)
    - sheetData = read data from sheet from row 2 onwards, in batches of 200 rows at a time
      - sheetDataBatch is single batch data
      - for each sheetRec of sheetBatchData
          - dbRow = Map values from sheet column layout to database column layout. Use row, tableColumnNames, sheetColumnNames
          - collect dbRows
          - refer to ExportImportService._importCsvData on how to use model_factory to convert csv cell data is mapped to db format for values.  Similarly convert sheet cell format to db format
      - INSERT INTO TABLE tableName from dbRows
- ChangeLogUtils().initializeChangeLogFromDataTables


UploadToGoogleSheetDialog. In the method _uploadToGoogleSheets, we dont need another confirmation popup.  


remove function "Uplaod to Google Sheets" from CommonOverflowMenu.  
In SettingsScreen, in "Developer Options" section, before "Clear All Data" include two functions.  Both buttons to be visible only when we have a valid value in SettingsManager.instance.googleSheetId.value
- Upload to Google Sheets
- Import from Google Sheets


class Currency {
  // ... existing code ...
  
  static const Map<String, Type> fieldTypes = {
    'name': String,
    'description': String,
    'symbol': String,
    'numberOfDecimalPlaces': int,
    'isDefault': bool,
    'updatedAt': DateTime,
  };
  
  Type? getFieldType(String fieldName) {
    return fieldTypes[fieldName];
  }
}


In all these classes introduce static fieldTypes constant, getFieldType methods
Basket
BasketItem
ChangeLog
CondensedChangeLog
Currency
LocalSettingsKeys
LocalSetting
Manufacturer
ManufacturerMaterial
ManufacturerMaterialWithDetails
Material
Project
PurchaseOrder
PurchaseOrderItem
PurchaseOrderPayment
Quotation
QuotationItem
UnitOfMeasure
Vendor
VendorPriceList
VendorPriceListWithDetails



for all model classes, I need _entityToDbFields, getDatabseFieldName, _dbToEntityFields_, 

static const Map<String, String> _entityToDbFields = {
    'name': 'name',
    'description': 'description',
    'symbol': 'symbol',
    'numberOfDecimalPlaces': 'number_of_decimal_places',
    'isDefault': 'is_default',
    'updatedAt': 'updated_at',
  };

  static String? getDatabseFieldName(String entifyField) => _entityToDbFields[entifyField];

  static const Map<String, String> _dbToEntityFields_ = {
    'name': 'name',
    'description': 'description',
    'symbol': 'symbol',
    'number_of_decimal_places': 'numberOfDecimalPlaces',
    'is_default': 'isDefault',
    'updated_at': 'updatedAt',
  };

  static String? getEntityFieldName(String dbFieldName) => _dbToEntityFields_[dbFieldName];