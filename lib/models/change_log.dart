import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class ChangeLogFields {
  static const uuid = 'uuid';
  static const tableIndex = 'tableIndex';
  static const tableKey = 'tableKey';
  static const changeMode = 'changeMode';
  static const updatedAt = 'updatedAt';
}

abstract class ChangeLogTableFields {
  static const uuid = 'uuid';
  static const tableIndex = 'table_index';
  static const tableKey = 'table_key';
  static const changeMode = 'change_mode';
  static const updatedAt = 'updated_at';
}

class ChangeLog {
  final String uuid;
  final int tableIndex;
  final String tableKey;
  final String changeMode;
  final DateTime updatedAt;

  ChangeLog({
    required this.uuid,
    required this.tableIndex,
    required this.tableKey,
    required this.changeMode,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      ChangeLogTableFields.uuid: uuid,
      ChangeLogTableFields.tableIndex: tableIndex,
      ChangeLogTableFields.tableKey: tableKey,
      ChangeLogTableFields.changeMode: changeMode,
      ChangeLogTableFields.updatedAt: updatedAt,
    };
  }

  factory ChangeLog.fromMap(Map<String, dynamic> map) {
    return ChangeLog(
      uuid: map[ChangeLogTableFields.uuid],
      tableIndex: map[ChangeLogTableFields.tableIndex],
      tableKey: map[ChangeLogTableFields.tableKey],
      changeMode: map[ChangeLogTableFields.changeMode],
      updatedAt: map[ChangeLogTableFields.updatedAt],
    );
  }

  @override
  String toString() {
    return 'ChangeLog(uuid: $uuid, tableIndex: $tableIndex, tableKey: $tableKey, changeMode: $changeMode, updatedAt: $updatedAt)';
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: ChangeLogFields.uuid,
      tableFieldName: ChangeLogTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _tableIndexFieldDef = ModelFieldDefinition(
      name: ChangeLogFields.tableIndex,
      tableFieldName: ChangeLogTableFields.tableIndex,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _tableKeyFieldDef = ModelFieldDefinition(
      name: ChangeLogFields.tableKey,
      tableFieldName: ChangeLogTableFields.tableKey,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _changeModeFieldDef = ModelFieldDefinition(
      name: ChangeLogFields.changeMode,
      tableFieldName: ChangeLogTableFields.changeMode,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: ChangeLogFields.updatedAt,
      tableFieldName: ChangeLogTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'ChangeLog',
      databaseTableName: TableNames.changeLog,
      type: ModelTypes.log,
      displayName: 'Change Log',
      tableIndex: -1,
      fromMap: ChangeLog.fromMap,
      toMap: (dynamic instance) => (instance as ChangeLog).toMap(),
      fields: {
        ChangeLogFields.uuid: _uuidFieldDef,
        ChangeLogFields.tableIndex: _tableIndexFieldDef,
        ChangeLogFields.tableKey: _tableKeyFieldDef,
        ChangeLogFields.changeMode: _changeModeFieldDef,
        ChangeLogFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory ChangeLog.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as ChangeLog;
  }
}
