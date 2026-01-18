import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

/// Constants for local setting keys
class LocalSettingsKeys {
  LocalSettingsKeys._();
  static const googleSheetId = 'google_sheet_id';
  static const webAppUrl = 'web_app_url';
  static const secretCode = 'secret_code';
  static const lastSyncTimestamp = 'last_sync_timestamp';
  static const developerMode = 'developer-mode';
  static const syncPaused = 'sync-paused';
}

abstract class LocalSettingFields {
  static const key = 'key';
  static const value = 'value';
  static const updatedAt = 'updatedAt';
}

abstract class LocalSettingTableFields {
  static const key = 'key';
  static const value = 'value';
  static const updatedAt = 'updated_at';
}

class LocalSetting {
  final String key; // Primary key
  final String value;
  final DateTime updatedAt;

  LocalSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      LocalSettingTableFields.key: key,
      LocalSettingTableFields.value: value,
      LocalSettingTableFields.updatedAt: updatedAt,
    };
  }

  factory LocalSetting.fromMap(Map<String, dynamic> map) {
    return LocalSetting(
      key: map[LocalSettingTableFields.key],
      value: map[LocalSettingTableFields.value],
      updatedAt: map[LocalSettingTableFields.updatedAt],
    );
  }

  LocalSetting copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return LocalSetting(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LocalSetting(key: $key, value: $value, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocalSetting &&
        other.key == key &&
        other.value == value &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return key.hashCode ^ value.hashCode ^ updatedAt.hashCode;
  }

  static final _keyFieldDef = ModelFieldDefinition(
      name: LocalSettingFields.key,
      tableFieldName: LocalSettingTableFields.key,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _valueFieldDef = ModelFieldDefinition(
      name: LocalSettingFields.value,
      tableFieldName: LocalSettingTableFields.value,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: LocalSettingFields.updatedAt,
      tableFieldName: LocalSettingTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'LocalSetting',
      databaseTableName: TableNames.localSettings,
      type: ModelTypes.settings,
      displayName: 'Local Setting',
      tableIndex: -100,
      fromMap: LocalSetting.fromMap,
      toMap: (dynamic instance) => (instance as LocalSetting).toMap(),
      fields: {
        LocalSettingFields.key: _keyFieldDef,
        LocalSettingFields.value: _valueFieldDef,
        LocalSettingFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory LocalSetting.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as LocalSetting;
  }
}
