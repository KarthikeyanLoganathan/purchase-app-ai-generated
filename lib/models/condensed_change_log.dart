import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class CondensedChangeLogFields {
  static const uuid = 'uuid';
  static const tableIndex = 'tableIndex';
  static const tableKey = 'tableKey';
  static const changeMode = 'changeMode';
  static const updatedAt = 'updatedAt';
}

abstract class CondensedChangeLogTableFields {
  static const uuid = 'uuid';
  static const tableIndex = 'table_index';
  static const tableKey = 'table_key';
  static const changeMode = 'change_mode';
  static const updatedAt = 'updated_at';
}

class CondensedChangeLog {
  final String uuid;
  final int tableIndex;
  final String tableKey;
  final String changeMode;
  final DateTime updatedAt;

  CondensedChangeLog({
    required this.uuid,
    required this.tableIndex,
    required this.tableKey,
    required this.changeMode,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      CondensedChangeLogTableFields.uuid: uuid,
      CondensedChangeLogTableFields.tableIndex: tableIndex,
      CondensedChangeLogTableFields.tableKey: tableKey,
      CondensedChangeLogTableFields.changeMode: changeMode,
      CondensedChangeLogTableFields.updatedAt: updatedAt,
    };
  }

  factory CondensedChangeLog.fromMap(Map<String, dynamic> map) {
    return CondensedChangeLog(
      uuid: map[CondensedChangeLogTableFields.uuid],
      tableIndex: map[CondensedChangeLogTableFields.tableIndex],
      tableKey: map[CondensedChangeLogTableFields.tableKey],
      changeMode: map[CondensedChangeLogTableFields.changeMode],
      updatedAt: map[CondensedChangeLogTableFields.updatedAt],
    );
  }

  @override
  String toString() {
    return 'CondensedChangeLog(uuid: $uuid, tableIndex: $tableIndex, tableKey: $tableKey, changeMode: $changeMode, updatedAt: $updatedAt)';
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: CondensedChangeLogFields.uuid,
      tableFieldName: CondensedChangeLogTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _tableIndexFieldDef = ModelFieldDefinition(
      name: CondensedChangeLogFields.tableIndex,
      tableFieldName: CondensedChangeLogTableFields.tableIndex,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _tableKeyFieldDef = ModelFieldDefinition(
      name: CondensedChangeLogFields.tableKey,
      tableFieldName: CondensedChangeLogTableFields.tableKey,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _changeModeFieldDef = ModelFieldDefinition(
      name: CondensedChangeLogFields.changeMode,
      tableFieldName: CondensedChangeLogTableFields.changeMode,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: CondensedChangeLogFields.updatedAt,
      tableFieldName: CondensedChangeLogTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'CondensedChangeLog',
      databaseTableName: TableNames.condensedChangeLog,
      type: ModelTypes.log,
      displayName: 'Condensed Change Log',
      tableIndex: -2,
      fromMap: CondensedChangeLog.fromMap,
      toMap: (dynamic instance) => (instance as CondensedChangeLog).toMap(),
      fields: {
        CondensedChangeLogFields.uuid: _uuidFieldDef,
        CondensedChangeLogFields.tableIndex: _tableIndexFieldDef,
        CondensedChangeLogFields.tableKey: _tableKeyFieldDef,
        CondensedChangeLogFields.changeMode: _changeModeFieldDef,
        CondensedChangeLogFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory CondensedChangeLog.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as CondensedChangeLog;
  }
}
