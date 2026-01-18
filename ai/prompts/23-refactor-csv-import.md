Refactor lib/csv_import_service.dart.  Use getCsvFiles() approach elaborated below.  

implement function importSingleCsv(tableName, csvfileName)
  - learn from logic in ib/csv_import_service.dart
    - handling of \n\r, \n; handling of empty lines; handling of headers, mapping values to columns
  - map values from csv line to columns
  - collect records to be inserted in a collection
  - do mass insert into SQlite DB
  - collect and return statistics


iterate through csvFilesList into fileName
  - tableName = fileNamePrefix part of the fileName without .csv without prefix sample-data/. 
    - for example if csv file name is sample-data/currencies.csv, then tableName should be currencies
  - call importSingleCsv(tableName, fileName)
  - collect statistics and report as it was happening before in the module
  


```dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<List<String>> getCsvFiles() async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
  
  // Filter for .csv files in the backend directory
  final files = manifestMap.keys
      .where((String key) => 
          key.startsWith('data') && 
          key.endsWith('.csv'))
      .toList();
  
  return files;
}
```




This implementation lacks data type handling.  Can you use reflection to understand data types as defined in models/table_name.dart and accordingly translate values?