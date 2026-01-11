HomeScreen  _showFirstTimeImportDialog should include 3 options if user is not logged in
- Setup Google Sheets
- Login
- Import Sample Data (works without sync)

## ✅ COMPLETED: CSV Export Feature

Settings Screen - When Developer Mode is On - allows export of data
- ✅ Transfer individual table data to corresponding table.csv files
- ✅ Put the tableName.csv files together in a {timestamp-YYYY-MM-DD-HH-MM-SS}-purchase-app-data.zip
- ✅ Allow user to Download/Share the zip file via system share dialog
- ✅ Created csv_export_service.dart with:
  - Export all database tables to CSV format
  - Bundle CSV files into timestamped zip archive
  - Share/save functionality via share_plus package
  - Export summary showing tables and row counts
- ✅ Added archive package to pubspec.yaml
- ✅ Added "Export Data" button in Settings Screen (visible when Developer Mode is ON)


Settings Screen - When Developer Mode is On - should allow export of data
- transfer individual table data to correspondign table.csv
- put the tableName.csv files together in a {timestamp-YYYY-MM-DD-HH-MM-SS}-purchase-app-data.zip
- Allow user to Downlaod the file p{timestamp-YYYY-MM-DD-HH-MM-SS}-purchase-app-data.zip or to save the file in device file system.

Accordingly develop suitable csv_export_service.dart also


This CsvImportService functionality imports sample data from sample-data/*.csv files from asset directory

Can you extend this capability to all tables.  it only covers few tables.  

Also extend the capability to import csv data from given sources
- CSV sample data from assets sample-data/*.csv
- Import data from given zip of csv files, the path of zip file comes as input

SettingsScreen to be adjusted to use the refactored version of CsvImportService to import sample data

SettingsScreen to offer one more capability.  "Import Data" (after "Export Data" button), to be able to import from given file.  File to be chosen in a file section popup/feature for interactive file selction of the .zip file
