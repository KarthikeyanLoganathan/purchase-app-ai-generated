class CondensedChangeLog {
  final String uuid;
  final int tableIndex;
  final String tableKey;
  final String changeMode;
  final String updatedAt;

  CondensedChangeLog({
    required this.uuid,
    required this.tableIndex,
    required this.tableKey,
    required this.changeMode,
    required this.updatedAt,
  });

  factory CondensedChangeLog.fromMap(Map<String, dynamic> map) {
    return CondensedChangeLog(
      uuid: map['uuid'] as String,
      tableIndex: map['table_index'] as int,
      tableKey: map['table_key'] as String,
      changeMode: map['change_mode'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'table_index': tableIndex,
      'table_key': tableKey,
      'change_mode': changeMode,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'CondensedChangeLog(uuid: $uuid, tableIndex: $tableIndex, tableKey: $tableKey, changeMode: $changeMode, updatedAt: $updatedAt)';
  }
}
