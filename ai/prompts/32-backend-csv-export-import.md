in line with   csvExportCurrentSheet, we need a mechanism csvImportTableData(tableName, csvDataString).  Consider Date columns, format vaues from UTC string to Date accordingly



in line with function csvExportOfDataSheetsBySelectedTypes we need csvImportOfDataSheetsBySelectedTypes.  User should be able to select zip file in dialog.

can you mae csvImportOfDataSheetsBySelectedTypes as server side zip extraction 


as you clear sheet, can you delete rows more than 2; before setting values


you need to delete row 3 onwards.  Sheets have 1 frozen row, second row has to be cleared

in the csvImportTableData, original excel column sequece should not be changed

in the csvImportTableData, original target sheet column header sequece should not be changed irrespective of csv column header sequence