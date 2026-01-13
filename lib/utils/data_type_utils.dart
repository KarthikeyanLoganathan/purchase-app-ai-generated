abstract class DataTypeUtils {
  static final Map<Type, dynamic Function(dynamic)> dbDeserializersNullable =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeNullableFromDb,
    bool: _deserializeBoolNullableFromDb,
    String: _deserializeStringNullable,
    double: _deserializeDoubleNullable,
    int: _deserializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> dbDeserializers =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeFromDb,
    bool: _deserializeBoolFromDb,
    String: _deserializeString,
    double: _deserializeDouble,
    int: _deserializeInt,
  });
  static final Map<Type, dynamic Function(dynamic)> csvDeserializersNullable =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeNullableFromCsv,
    bool: _deserializeBoolNullableFromCsv,
    String: _deserializeStringNullable,
    double: _deserializeDoubleNullable,
    int: _deserializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> csvDeserializers =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeFromCsv,
    bool: _deserializeBoolFromCsv,
    String: _deserializeString,
    double: _deserializeDouble,
    int: _deserializeInt,
  });
  static final Map<Type, dynamic Function(dynamic)> sheetDeserializersNullable =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeNullableFromSheet,
    bool: _deserializeBoolNullableFromSheet,
    String: _deserializeStringNullable,
    double: _deserializeDoubleNullable,
    int: _deserializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> sheetDeserializers =
      Map.unmodifiable({
    DateTime: _deserializeDateTimeFromSheet,
    bool: _deserializeBoolFromSheet,
    String: _deserializeString,
    double: _deserializeDouble,
    int: _deserializeInt,
  });

  static final Map<Type, dynamic Function(dynamic)> dbSerializersNullable =
      Map.unmodifiable({
    DateTime: _serializeDateTimeNullableToDb,
    bool: _serializeBoolNullableToDb,
    String: _serializeStringNullable,
    double: _serializeDoubleNullable,
    int: _serializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> dbSerializers =
      Map.unmodifiable({
    DateTime: _serializeDateTimeToDb,
    bool: _serializeBoolToDb,
    String: _serializeString,
    double: _serializeDouble,
    int: _serializeInt,
  });
  static final Map<Type, dynamic Function(dynamic)> csvSerializersNullable =
      Map.unmodifiable({
    DateTime: _serializeDateTimeNullableToCsv,
    bool: _serializeBoolNullableToCsv,
    String: _serializeStringNullable,
    double: _serializeDoubleNullable,
    int: _serializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> csvSerializers =
      Map.unmodifiable({
    DateTime: _serializeDateTimeToCsv,
    bool: _serializeBoolToCsv,
    String: _serializeString,
    double: _serializeDouble,
    int: _serializeInt,
  });
  static final Map<Type, dynamic Function(dynamic)> sheetSerializersNullable =
      Map.unmodifiable({
    DateTime: _serializeDateTimeNullableToSheet,
    bool: _serializeBoolNullableToSheet,
    String: _serializeStringNullable,
    double: _serializeDoubleNullable,
    int: _serializeIntNullable,
  });
  static final Map<Type, dynamic Function(dynamic)> sheetSerializers =
      Map.unmodifiable({
    DateTime: _serializeDateTimeToSheet,
    bool: _serializeBoolToSheet,
    String: _serializeString,
    double: _serializeDouble,
    int: _serializeInt,
  });

  static double? _toGoogleSheetsDate(DateTime? dateTime) {
    if (dateTime == null) return null;
    final epoch = DateTime(1899, 12, 30);
    final difference = dateTime.difference(epoch);
    return difference.inMilliseconds / (24 * 60 * 60 * 1000);
  }

  static DateTime? _fromGoogleSheetsDate(double? serialDate) {
    if (serialDate == null) return null;
    final epoch = DateTime(1899, 12, 30);
    final milliseconds = (serialDate * 24 * 60 * 60 * 1000).round();
    return epoch.add(Duration(milliseconds: milliseconds));
  }

  static DateTime? _deserializeDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static bool? _deserializeBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value > 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return false;
  }

  static double? _deserializeDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _deserializeIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _deserializeDateTimeNullableFromDb(dynamic value) {
    return _deserializeDateTime(value);
  }

  static DateTime? _deserializeDateTimeNullableFromCsv(dynamic value) {
    return _deserializeDateTime(value);
  }

  static DateTime? _deserializeDateTimeNullableFromSheet(dynamic value) {
    return _fromGoogleSheetsDate(_deserializeDouble(value));
  }

  static String? _serializeDateTimeNullableToDb(dynamic value) {
    return (value as DateTime?)?.toUtc().toIso8601String();
  }

  static String? _serializeDateTimeNullableToCsv(dynamic value) {
    return (value as DateTime?)?.toUtc().toIso8601String();
  }

  static double? _serializeDateTimeNullableToSheet(dynamic value) {
    return _toGoogleSheetsDate(value as DateTime?);
  }

  static DateTime _deserializeDateTimeFromDb(dynamic value) {
    return _deserializeDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime _deserializeDateTimeFromCsv(dynamic value) {
    return _deserializeDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime _deserializeDateTimeFromSheet(dynamic value) {
    return _deserializeDateTimeNullableFromSheet(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _serializeDateTimeToDb(dynamic value) {
    return (value as DateTime).toUtc().toIso8601String();
  }

  static String _serializeDateTimeToCsv(dynamic value) {
    return (value as DateTime).toUtc().toIso8601String();
  }

  static double _serializeDateTimeToSheet(dynamic value) {
    return _toGoogleSheetsDate(value as DateTime)!;
  }

  static String? _deserializeStringNullable(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static String? _serializeStringNullable(dynamic value) {
    return (value as String?).toString().trim();
  }

  static String _deserializeString(dynamic value) {
    return _deserializeStringNullable(value) ?? '';
  }

  static String _serializeString(dynamic value) {
    return _serializeStringNullable(value as String?) ?? '';
  }

  static bool? _deserializeBoolNullableFromDb(dynamic value) {
    return _deserializeBool(value);
  }

  static bool? _deserializeBoolNullableFromCsv(dynamic value) {
    return _deserializeBool(value);
  }

  static bool? _deserializeBoolNullableFromSheet(dynamic value) {
    return _deserializeBool(value);
  }

  static int? _serializeBoolNullableToDb(dynamic value) {
    final boolValue = value as bool?;
    if (boolValue == null) return null;
    return boolValue ? 1 : 0;
  }

  static String? _serializeBoolNullableToCsv(dynamic value) {
    final boolValue = value as bool?;
    if (boolValue == null) return null;
    return boolValue ? 'true' : 'false';
  }

  static bool? _serializeBoolNullableToSheet(dynamic value) {
    return value as bool?;
  }

  static bool _deserializeBoolFromDb(dynamic value) {
    return _deserializeBoolNullableFromDb(value) ?? false;
  }

  static bool _deserializeBoolFromCsv(dynamic value) {
    return _deserializeBoolNullableFromCsv(value) ?? false;
  }

  static bool _deserializeBoolFromSheet(dynamic value) {
    return _deserializeBoolNullableFromSheet(value) ?? false;
  }

  static int _serializeBoolToDb(dynamic value) {
    return _serializeBoolNullableToDb(value as bool?) ?? 0;
  }

  static String _serializeBoolToCsv(dynamic value) {
    return _serializeBoolNullableToCsv(value as bool?) ?? "false";
  }

  static bool _serializeBoolToSheet(dynamic value) {
    return _serializeBoolNullableToSheet(value as bool?) ?? false;
  }

  static double? _serializeDoubleNullable(dynamic value) {
    return value as double?;
  }

  static double _deserializeDouble(dynamic value) {
    return _deserializeDoubleNullable(value) ?? 0.0;
  }

  static double _serializeDouble(dynamic value) {
    return _serializeDoubleNullable(value as double?) ?? 0.0;
  }

  static int _deserializeInt(dynamic value) {
    return _deserializeIntNullable(value) ?? 0;
  }

  static int? _serializeIntNullable(dynamic value) {
    return value as int?;
  }

  static int _serializeInt(dynamic value) {
    return _serializeIntNullable(value as int?) ?? 0;
  }
}
