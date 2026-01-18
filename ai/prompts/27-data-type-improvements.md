in all model classes 
- rename toMap() to toDbMap()
   - provide copy of the method as toCsvMap()
   - provide copy of the method as toSheetMap()
- rename fromMap() to fromDbMap()
   - provide copy of the method as fromCsvMap()
   - provide copy of the method as fromSheetMap()

---

## Verification Steps Performed

### Q1: Verify format-specific method usage consistency
**Question:** "ensure toDbMap uses ToDb methods, toCsvMap uses ToCsv, toSheetMap uses ToSheet, fromDbMap uses FromDb, fromCsvMap uses FromCsv, fromSheetMap uses FromSheet"

**Response:** Verified all 18 model classes using comprehensive Python validation script:
- ✅ `toDbMap()` uses only `...ToDb` methods (e.g., `serializeDateTimeToDb`, `serializeBoolToDb`)
- ✅ `toCsvMap()` uses only `...ToCsv` methods (e.g., `serializeDateTimeToCsv`, `serializeBoolToCsv`)
- ✅ `toSheetMap()` uses only `...ToSheet` methods (e.g., `serializeDateTimeToSheet`, `serializeBoolToSheet`)
- ✅ `fromDbMap()` uses only `...FromDb` methods (e.g., `deserializeDateTimeFromDb`, `deserializeBoolFromDb`)
- ✅ `fromCsvMap()` uses only `...FromCsv` methods (e.g., `deserializeDateTimeFromCsv`, `deserializeBoolFromCsv`)
- ✅ `fromSheetMap()` uses only `...FromSheet` methods (e.g., `deserializeDateTimeFromSheet`, `deserializeBoolFromSheet`)

No generic method calls (e.g., `serializeDateTime()`, `deserializeBool()`) remain in any model file.

### Q2: Verify string literal to constant conversions
**Question:** "can you check uncommitted string literal to constant changes if the old and new values are correct"

**Response:** Validated all string literal to TableNames constant conversions against `data_definition.dart`:

**All conversions verified correct:**
- `'currencies'` → `TableNames.currencies` ✓
- `'unit_of_measures'` → `TableNames.unitOfMeasures` ✓
- `'manufacturers'` → `TableNames.manufacturers` ✓
- `'vendors'` → `TableNames.vendors` ✓
- `'materials'` → `TableNames.materials` ✓
- `'manufacturer_materials'` → `TableNames.manufacturerMaterials` ✓
- `'vendor_price_lists'` → `TableNames.vendorPriceLists` ✓
- `'projects'` → `TableNames.projects` ✓
- `'baskets'` → `TableNames.baskets` ✓
- `'basket_items'` → `TableNames.basketItems` ✓
- `'quotations'` → `TableNames.quotations` ✓
- `'quotation_items'` → `TableNames.quotationItems` ✓
- `'purchase_orders'` → `TableNames.purchaseOrders` ✓
- `'purchase_order_items'` → `TableNames.purchaseOrderItems` ✓
- `'purchase_order_payments'` → `TableNames.purchaseOrderPayments` ✓
- `'local_settings'` → `TableNames.localSettings` ✓
- `'change_log'` → `TableNames.changeLog` ✓
- `'condensed_change_log'` → `TableNames.condensedChangeLog` ✓

Files affected: `currencies_screen.dart`, `currency_detail_screen.dart`, `unit_of_measure_detail_screen.dart`, `units_screen.dart`, `app_helper.dart`, `database_helper.dart`

### Q3: Verify DataTypeUtils logic consistency
**Question:** "check DataTypeUtils if the logic is largely consistent with method names"

**Response:** Analyzed all DataTypeUtils methods for logical consistency:

**✅ DateTime Methods - CONSISTENT:**
- `FromDb/FromCsv`: Both use ISO8601 string parsing via `_deserializeDateTime()`
- `FromSheet`: Uses Google Sheets serial date conversion via `_fromGoogleSheetsDate()`
- `ToDb/ToCsv`: Both return ISO8601 string via `toUtc().toIso8601String()`
- `ToSheet`: Returns Google Sheets serial date (double) via `_toGoogleSheetsDate()`

**✅ Boolean Methods - CONSISTENT:**
- `FromDb/FromCsv/FromSheet`: All use same logic via `_deserializeBool()`
- `ToDb`: Returns integer (0/1) for SQLite storage
- `ToCsv`: Returns string ('true'/'false') for CSV format
- `ToSheet`: Returns boolean (native Google Sheets type)

**✅ String Methods - CONSISTENT:**
- All deserialize/serialize methods are format-agnostic (same logic across Db/Csv/Sheet)
- Consistently trim strings and handle null values

**✅ Numeric Methods (Int/Double) - CONSISTENT:**
- All deserialize/serialize methods are format-agnostic
- No format-specific variants needed (numbers are universally compatible)

**Conclusion:** 100% logical consistency confirmed. Each method's implementation correctly matches its semantic purpose based on the target format (Database SQLite types, CSV text representations, Google Sheets native types).


In all model class files, do enhancement like this to add {model}Fields, {model}TableFields

class CurrencyFields {
   static const name = 'name',
   static const description: 'description',
   static const symbol: 'symbol',
   static const numberOfDecimalPlaces: 'numberOfDecimalPlaces',
   static const isDefault: 'isDefault',
   static const updatedAt: 'updatedAt',
}

class CurrencyTableFields {
   static const name = 'name',
   static const description: 'description',
   static const symbol: 'symbol',
   static const numberOfDecimalPlaces: 'number_of_decimal_places',
   static const isDefault: 'is_default',
   static const updatedAt: 'updated_at',
}


class Currency {
  static const Map<String, Type> _fieldTypes = {
    'name': String,
    'description': String,
    'symbol': String,
    'numberOfDecimalPlaces': int,
    'isDefault': bool,
    'updatedAt': DateTime,
  };

  ...




  In all model classes, do enhancement like this add fromMap, toMap methods

  class Currency {
  ...  
  ...


  Map<String, dynamic> toMap() {
    return {
      CurrencyFields.name: name,
      CurrencyFields.description: description,
      CurrencyFields.symbol: symbol,
      CurrencyFields.numberOfDecimalPlaces: numberOfDecimalPlaces,
      CurrencyFields.isDefault: isDefault,
      CurrencyFields.updatedAt: updatedAt,
    };
  }

  Currency fromMap(Map<String, dynamic> map) {
    return Currency({
      name: map[CurrencyFields.name],
      description: map[CurrencyFields.description],
      symbol: map[CurrencyFields.symbol],
      numberOfDecimalPlaces: map[CurrencyFields.numberOfDecimalPlaces],
      isDefault: map[CurrencyFields.isDefault],
      updatedAt map[CurrencyFields.updatedAt],
    });
  }
} //Currency





in all model classes, delete toCsvMap, fromCsvMap, toSheetMap, fromSheetMap, toDbMap, fromDbMap, _fieldTypes, getFieldType, _entityToDbFields, getDatabaseFieldName


in all model classes delete _dbToEntityFields




Take Currency.dart, Currency model class as example.

For each {filed}, of the model, considering if it is nullable, considering its type, generate _{field}FieldDef static attributes.  Also generate modelDefinition inside the model classes