/// Utility class for type conversion operations
/// Used when importing/exporting data from CSV or Google Sheets
class DataTypeUtils {
  /// Pre-convert strings to types expected by model factories
  /// This handles int, bool conversions that models expect
  static Map<String, dynamic> preConvertTypes(Map<String, dynamic> rawRecord) {
    final Map<String, dynamic> converted = {};

    rawRecord.forEach((key, value) {
      if (value == null) {
        converted[key] = null;
        return;
      }

      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) {
        converted[key] = null;
        return;
      }

      // Handle known integer fields
      if (key == 'number_of_decimal_places' ||
          key == 'table_index' ||
          key.endsWith('_id') && key != 'uuid' ||
          key.contains('decimal_places') ||
          key.contains('size') ||
          key.contains('quantity')) {
        converted[key] = int.tryParse(stringValue);
        return;
      }

      // Handle boolean fields (keep as int 0/1 for SQLite)
      if (key.startsWith('is_') || key == 'active' || key == 'completed') {
        final boolValue = stringValue == '1' ||
            stringValue.toLowerCase() == 'true' ||
            stringValue.toLowerCase() == 'yes';
        converted[key] = boolValue ? 1 : 0;
        return;
      }

      // Handle decimal/double fields
      if (key.contains('price') ||
          key.contains('rate') ||
          key.contains('amount') ||
          key.contains('tax') ||
          key.contains('percent')) {
        converted[key] = double.tryParse(stringValue);
        return;
      }

      // Default: keep as string
      converted[key] = stringValue;
    });

    return converted;
  }

  /// Convert record types using heuristic type detection
  /// Used when model factory is not available or fails
  ///
  /// [rawRecord] - Map of column name to string value
  /// [headers] - Optional list of headers to process (if null, uses all keys in rawRecord)
  static Map<String, dynamic> convertRecordTypes(Map<String, dynamic> rawRecord,
      [List<String>? headers]) {
    final Map<String, dynamic> converted = {};
    final keysToProcess = headers ?? rawRecord.keys.toList();

    for (String key in keysToProcess) {
      final value = rawRecord[key];
      converted[key] = parseValue(key, value);
    }

    return converted;
  }

  /// Parse cell value based on column name/type (fallback heuristic method)
  /// Returns SQLite-compatible types: num, String, or null
  static dynamic parseValue(String columnName, dynamic cellValue) {
    if (cellValue == null) return null;

    final stringValue = cellValue.toString().trim();
    if (stringValue.isEmpty) return null;

    // Handle dates - return ISO8601 string
    if (columnName.contains('updated_at') ||
        columnName.contains('created_at') ||
        columnName.contains('_date')) {
      try {
        return DateTime.parse(stringValue).toIso8601String();
      } catch (e) {
        return DateTime.now().toUtc().toIso8601String();
      }
    }

    // Handle booleans - SQLite needs 0/1 (int), not true/false
    if (columnName.startsWith('is_') ||
        columnName == 'active' ||
        columnName == 'completed') {
      final boolValue = stringValue == '1' ||
          stringValue.toLowerCase() == 'true' ||
          stringValue.toLowerCase() == 'yes';
      return boolValue ? 1 : 0; // Convert to int for SQLite
    }

    // Handle UUIDs and text fields - keep as string
    if (columnName == 'uuid' ||
        columnName == 'name' ||
        columnName == 'code' ||
        columnName == 'description' ||
        columnName.contains('_at') ||
        columnName.contains('url')) {
      return stringValue;
    }

    // Handle integers
    if (columnName == 'table_index' ||
        (columnName.endsWith('_id') && columnName != 'uuid')) {
      return int.tryParse(stringValue);
    }

    if (columnName.contains('decimal_places') ||
        columnName.contains('size') ||
        columnName.contains('quantity')) {
      return int.tryParse(stringValue) ?? 0;
    }

    // Handle decimals/doubles
    if (columnName.contains('price') ||
        columnName.contains('rate') ||
        columnName.contains('amount') ||
        columnName.contains('tax') ||
        columnName.contains('percent')) {
      return double.tryParse(stringValue) ?? 0.0;
    }

    // Try to detect type by value
    if (int.tryParse(stringValue) != null) {
      return int.parse(stringValue);
    } else if (double.tryParse(stringValue) != null) {
      return double.parse(stringValue);
    }

    // Default: return as string
    return stringValue;
  }
}
