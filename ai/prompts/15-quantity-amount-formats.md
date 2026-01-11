help me add 2 configuration tables given below both in backend and froentend.  Dont need DDL version history in SQLite. Consider it a fresh start.
- unit_of_measures - table_index 101
  - name (text) key
  - description (text)
  - is_default (boolean)
  - number_of_decimal_places (number)
  - updated_at (timestamp)
- currencies - table_index 102
  - name (text) key
  - description (text)
  - symbol (text)
  - number_of_decimal_places (number)
  - is_default (boolean)
  - updated_at (timestamp)

In change_log table
- rename column table_key_uuid to table_key

In condensed_change_log table
- rename column table_key_uuid to table_key

Adjust the codebase across to take care of table_key_uuid.

So far, uuid has been the primary key column for transaction data, master data tables.  Hence forth, the nmae of the key column is identifiable by TABLE_DEFINITIONS[tableName].KEY_COLUMN.  Introduce an equivalent for SQLite in database_helper.dart

Include unit_of_measures and currencies in delta sync.

Adjust delta sync logic to use KEY_COLUMN in logic instead of assuming the column to be uuid.  When you change the logic, if local variable names have uuid in them, rename those variables to be semantically consistant.

Adjust consistencyChecks.js to use KEY_COLUMN in logic.  in this module instead of assuming uuid as the column, please use KEY_COLUMN from TABLE_DEFINITIONS, adjust local variable names to be semantically consistent

In Flutter App, CsvImportService to be adjusted to include currencies and unit_of_measures

In Flutter App, DatabaseHelper to be extended with getDefaultCurrency() and getDefaultUnitOfMeasure() functions.

In Flutter App, wherever we used INR as default currency hard-coded, we need to change it to DatabaseHelper.getDefaultCurrnecy( ).  Wherever we formatted amount fields to 2 decimal places, we need to use DatabaseHelper.getDefaultCurrnecy( ).number_of_decimal_places 

In Flutter App, we need Currencies list screen, currency maintainence feature.  Integrate it with HomeScreen at the end.

In Flutter App, we need Units (unit_of_measures) list screen, Unit maintainence feature.  Integrate it with HomeScreen at the end with title Units.

Add number_of_decimal_places field in unit_of_measures table.  Dont need DDL version history in SQLite. Consider it a fresh start.  Please adjust tableMetadata.js

In Flutter App, quantity & selling_lot_size fields in screens to use 

In Flutter App, wherever we formatted quantity & selling_lot_size fields to 2 decimal places, we need to use DatabaseHelper.getUnitOfMeasure( ).number_of_decimal_places 


unit_of_measure is used in multiple tables.  Please implement unit_of_measure on all screens to have suggest based input in Flutter App

currency is used in multiple tables.  Please implement currency on all screens to have suggest based input in Flutter App
