import 'package:purchase_app/utils/data_type_utils.dart';

abstract class ModelTypes {
  static const metadata = "METADATA"; //Not in use here
  static const settings = "SETTINGS";
  static const configuration = "CONFIGURATION_DATA";
  static const masterData = "MASTER_DATA";
  static const transactionData = "TRANSACTION_DATA";
  static const log = "LOG";
}

class ModelFieldDefinition {
  final String name;
  final String tableFieldName;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final Type type;

  ModelFieldDefinition(
      {required this.name,
      required this.tableFieldName,
      required this.isPrimaryKey,
      required this.isNullable,
      required this.isUnique,
      required this.type});
}

class ModelDefinition {
  final String name;
  final String databaseTableName;
  final String type;
  final String displayName;
  final int tableIndex;
  final Map<String, ModelFieldDefinition> fields;
  Map<String, ModelFieldDefinition>? _databaseFields;
  List<ModelFieldDefinition>? _fieldList;
  ModelFieldDefinition? _primaryKeyField;
  dynamic Function(Map<String, dynamic>) fromMap;
  Map<String, dynamic> Function(dynamic) toMap;
  ModelDefinition(
      {required this.name,
      required this.databaseTableName,
      required this.type,
      required this.displayName,
      required this.tableIndex,
      required this.fromMap,
      required this.toMap,
      required Map<String, ModelFieldDefinition> fields})
      : fields = Map.unmodifiable(fields) {
    Map<String, ModelFieldDefinition> dbFields = {};
    try {
      _primaryKeyField =
          fields.values.firstWhere((field) => field.isPrimaryKey);
    } catch (e) {
      _primaryKeyField = null;
    }
    _fieldList = List.unmodifiable(fields.values.toList());
    for (var field in fields.values) {
      dbFields[field.tableFieldName] = field;
    }
    _databaseFields = Map.unmodifiable(dbFields);
  }
  ModelFieldDefinition? get primaryKeyField => _primaryKeyField;
  ModelFieldDefinition? getFieldMetadata(String fieldName) => fields[fieldName];
  Map<String, ModelFieldDefinition> get databaseFields => _databaseFields!;
  ModelFieldDefinition? getDatabaseFieldMetadata(String databaseFieldName) =>
      _databaseFields![databaseFieldName];
  List<ModelFieldDefinition> get fieldList => _fieldList!;

  dynamic fromDbMap(Map<String, dynamic> map) {
    final Map<String, dynamic> record = {};
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        record[fieldDef.tableFieldName] = DataTypeUtils
            .dbDeserializersNullable[type]
            ?.call(map[fieldDef.tableFieldName]);
      } else {
        record[fieldDef.tableFieldName] = DataTypeUtils.dbDeserializers[type]
            ?.call(map[fieldDef.tableFieldName]);
      }
    }
    return fromMap(record);
  }

  Map<String, dynamic> toDbMap(dynamic modelInstance) {
    final Map<String, dynamic> result = {};
    final Map<String, dynamic> record = toMap(modelInstance);
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        result[fieldDef.tableFieldName] = DataTypeUtils
            .dbSerializersNullable[type]
            ?.call(record[fieldDef.tableFieldName]);
      } else {
        result[fieldDef.tableFieldName] = DataTypeUtils.dbSerializers[type]
            ?.call(record[fieldDef.tableFieldName]);
      }
    }
    return result;
  }

  dynamic fromCsvMap(Map<String, dynamic> map) {
    final Map<String, dynamic> record = {};
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        record[fieldDef.tableFieldName] = DataTypeUtils
            .csvDeserializersNullable[type]
            ?.call(map[fieldDef.tableFieldName]);
      } else {
        record[fieldDef.tableFieldName] = DataTypeUtils.csvDeserializers[type]
            ?.call(map[fieldDef.tableFieldName]);
      }
    }
    return fromMap(record);
  }

  Map<String, dynamic> toCsvMap(dynamic modelInstance) {
    final Map<String, dynamic> result = {};
    final Map<String, dynamic> record = toMap(modelInstance);
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        result[fieldDef.tableFieldName] = DataTypeUtils
            .csvSerializersNullable[type]
            ?.call(record[fieldDef.tableFieldName]);
      } else {
        result[fieldDef.tableFieldName] = DataTypeUtils.csvSerializers[type]
            ?.call(record[fieldDef.tableFieldName]);
      }
    }
    return result;
  }

  dynamic fromSheetMap(Map<String, dynamic> map) {
    final Map<String, dynamic> record = {};
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        record[fieldDef.tableFieldName] = DataTypeUtils
            .csvDeserializersNullable[type]
            ?.call(map[fieldDef.tableFieldName]);
      } else {
        record[fieldDef.tableFieldName] = DataTypeUtils.sheetDeserializers[type]
            ?.call(map[fieldDef.tableFieldName]);
      }
    }
    return fromMap(record);
  }

  Map<String, dynamic> toSheetMap(dynamic modelInstance) {
    final Map<String, dynamic> result = {};
    final Map<String, dynamic> record = toMap(modelInstance);
    for (var fieldDef in fields.values) {
      final type = fieldDef.type;
      final isNullable = fieldDef.isNullable;
      if (isNullable) {
        result[fieldDef.tableFieldName] = DataTypeUtils
            .csvSerializersNullable[type]
            ?.call(record[fieldDef.tableFieldName]);
      } else {
        result[fieldDef.tableFieldName] = DataTypeUtils.sheetSerializers[type]
            ?.call(record[fieldDef.tableFieldName]);
      }
    }
    return result;
  }
}
