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



in model classes fromMap methods have to be more tolerant

boolean values are arriving as true/false/TRUE/FALSE/... in string form.  They have to be appropriately treated as bool values


get me a list of model class, field, datatype
At the end give list of unique data types also

DateTime - Date and time objects
DateTime? - Nullable date and time
String - Text values
String? - Nullable text
bool - Boolean values (true/false)
double - Decimal numbers
double? - Nullable decimal numbers
int - Integer numbers
int? - Nullable integers


for each of these data types, provide methods
deserialize{DataType}()
serialize{DataType}() 

in the class DataTypeUtils



Model Classes with Fields and Data Types
Basket
uuid: String
id: int?
date: String
description: String?
expectedDeliveryDate: String?
totalPrice: double
currency: String
numberOfItems: int
projectUuid: String?
deliveryAddress: String?
phoneNumber: String?
updatedAt: String
BasketItem
uuid: String
basketUuid: String
id: int?
manufacturerMaterialUuid: String
materialUuid: String?
model: String?
manufacturerUuid: String?
quantity: double
unitOfMeasure: String?
maxRetailPrice: double?
price: double
currency: String
updatedAt: String
ChangeLog
uuid: String
tableIndex: int
tableKey: String
changeMode: String
updatedAt: String
CondensedChangeLog
uuid: String
tableIndex: int
tableKey: String
changeMode: String
updatedAt: String
Currency
name: String
description: String?
symbol: String?
numberOfDecimalPlaces: int
isDefault: bool
updatedAt: DateTime
LocalSetting
key: String
value: String
updatedAt: DateTime
Manufacturer
uuid: String
id: int?
name: String
description: String?
address: String?
phoneNumber: String?
emailAddress: String?
website: String?
photoUuid: String?
updatedAt: DateTime
ManufacturerMaterial
uuid: String
manufacturerUuid: String
materialUuid: String
model: String
sellingLotSize: double?
maxRetailPrice: double?
currency: String?
website: String?
partNumber: String?
photoUuid: String?
updatedAt: DateTime
Material
uuid: String
id: int?
name: String
description: String?
unitOfMeasure: String
website: String?
photoUuid: String?
updatedAt: DateTime
Project
uuid: String
name: String
description: String?
address: String?
phoneNumber: String?
geoLocation: String?
startDate: String?
endDate: String?
completed: int
updatedAt: String
PurchaseOrder
uuid: String
id: int?
vendorUuid: String
date: DateTime
basePrice: double
taxAmount: double
totalAmount: double
currency: String?
orderDate: DateTime
expectedDeliveryDate: DateTime?
amountPaid: double
amountBalance: double
completed: bool
basketUuid: String?
quotationUuid: String?
projectUuid: String?
description: String?
deliveryAddress: String?
phoneNumber: String?
updatedAt: DateTime
PurchaseOrderItem
uuid: String
purchaseOrderUuid: String
manufacturerMaterialUuid: String
materialUuid: String
model: String
quantity: double
rate: double
rateBeforeTax: double
basePrice: double
taxPercent: double
taxAmount: double
totalAmount: double
currency: String?
basketItemUuid: String?
quotationItemUuid: String?
unitOfMeasure: String?
updatedAt: DateTime
PurchaseOrderPayment
uuid: String
purchaseOrderUuid: String
date: DateTime
amount: double
currency: String?
upiRefNumber: String?
updatedAt: DateTime
Quotation
uuid: String
id: int?
basketUuid: String
vendorUuid: String
date: String
expectedDeliveryDate: String?
basePrice: double
taxAmount: double
totalAmount: double
currency: String
numberOfAvailableItems: int
numberOfUnavailableItems: int
projectUuid: String?
description: String?
updatedAt: String
QuotationItem
uuid: String
id: int?
quotationUuid: String
basketUuid: String
basketItemUuid: String
vendorPriceListUuid: String?
itemAvailableWithVendor: bool
manufacturerMaterialUuid: String?
materialUuid: String?
model: String?
quantity: double
maxRetailPrice: double?
rate: double
rateBeforeTax: double
basePrice: double
taxPercent: double
taxAmount: double
totalAmount: double
currency: String
unitOfMeasure: String?
updatedAt: String
UnitOfMeasure
name: String
description: String?
numberOfDecimalPlaces: int
isDefault: bool
updatedAt: DateTime
Vendor
uuid: String
id: int?
name: String
description: String?
address: String?
geoLocation: String?
phoneNumber: String?
emailAddress: String?
website: String?
photoUuid: String?
updatedAt: DateTime
VendorPriceList
uuid: String
manufacturerMaterialUuid: String
vendorUuid: String
rate: double
rateBeforeTax: double
currency: String?
taxPercent: double
taxAmount: double
updatedAt: DateTime
Unique Data Types Used
DateTime - Date and time objects
DateTime? - Nullable date and time
String - Text values
String? - Nullable text
bool - Boolean values (true/false)
double - Decimal numbers
double? - Nullable decimal numbers
int - Integer numbers
int? - Nullable integers



now use use DataTypeUtils.deserialize{dataType}, DataTypeUtils.serialize{dataType} methods in all model classes fromMap, toMap methods depending upon the type of fields

In many model classes updatedAt field is String.  This has to be DateTime


what about other date fields;  check all model classes where field names contain date or timestamp in their name.  Check if they are all datetime or not.  fix them






UploadToGoogleSheetDialog, ImportFromGoogleSheetDialog to show existing sheet info like in SetupGoogleSheetScreen.  Only sheet details to be shown.  Google drive pick option.  No need to display script details


SetupGoogleSheetScreen method _getScriptProjectId everytime creates a new Google Script App Deployment.  it should delete/archive previous active deployment before creating new deployment



SetupGoogleSheetScreen method _deployWebApp everytime creates a new Google Script App Deployment.  it should delete/archive previous active deployment before creating new deployment

the delete of old deployment consitently fails.  So, old deployment has to be archived

New behavior:

First attempts to delete the old deployment
If deletion fails (which you mentioned happens consistently), it falls back to archiving the deployment by:
Updating the deployment's description to mark it as "Archived"
Adding a timestamp of when it was replaced
Preserving the old deployment data
If both delete and archive fail, it logs a warning and continues with creating the new deployment
This approach ensures that:

Old deployments are properly marked as archived when deletion fails
The deployment history is preserved
The process continues even if cleanup operations fail
Clear debug messages help troubleshoot any issues


there is no technical route to delete the old deploymnet.  Dont attempt to delete old deployment.  Just archive it


in the updateConfig, where are you marking the deployment as archived?  Just changing description wont work - right?


Did we implement this logic in the snippet below?  Gemini gave this example


```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/script/v1.dart' as script;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AppsScriptManager {
  // Ensure you include the correct scope for deployments
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [script.ScriptApi.scriptDeploymentsScope],
  );

  Future<void> archiveDeployment(String scriptProjectId, String deploymentId) async {
    try {
      // 1. Sign in and get the authenticated client
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return; // User cancelled

      // 2. Obtain an authenticated HTTP client from the sign-in account
      var httpClient = await account.authenticatedClient();

      if (httpClient != null) {
        // 3. Initialize the Script API
        var api = script.ScriptApi(httpClient);

        // 4. Call the delete method (this archives the deployment)
        // In the Dart library, it is found under projects.deployments
        await api.projects.deployments.delete(scriptProjectId, deploymentId);
        
        print('Deployment $deploymentId archived successfully.');
      }
    } catch (e) {
      print('Error archiving deployment: $e');
    }
  }
}
```


yes, implement deletion logic.  There is a catch.  When you walk through existing deployments, are you making sure you got hold of an active deployment to archive it (meaning delete it)











timestamp getting written in ISO 8061 in excel upload.  to be checked





In Flutter Google Sheets API, when I send dart DateTime object I get error

Unhandled exception:
Converting object to an encodable object failed: Instance of 'JsonUnsupportedObjectError'
#0      _JsonStringifier.writeObject (dart:convert/json.dart:824:7)
#1      _JsonStringStringifier.printOn (dart:convert/json.dart:1024:17)
#2      _JsonStringStringifier.stringify (dart:convert/json.dart:1005:5)
#3      JsonEncoder.convert (dart:convert/json.dart:353:30)
#4      JsonCodec.encode (dart:convert/json.dart:238:45)
#5      jsonEncode (dart:convert/json.dart:118:12)
#6      ExportImportService.Eval ()
#7      ExportImportService.uploadDataToGoogleSheets (package:purchase_app/services/export_import_service.dart:792:9)
<asynchronous suspension>
#8      _SetupGoogleSheetScreenState._uploadDataToGoogleSheets (package:purchase_app/screens/setup_google_sheet_screen.dart:1006:22)
<asynchronous suspension>


How to send proper date time value