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

class LocalSetting {
  static const Map<String, Type> _fieldTypes = {
    'key': String,
    'value': String,
    'updatedAt': DateTime,
  };

  final String key; // Primary key
  final String value;
  final DateTime updatedAt;

  LocalSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  static const Map<String, String> _entityToDbFields = {
    'key': 'key',
    'value': 'value',
    'updatedAt': 'updated_at',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'key': 'key',
    'value': 'value',
    'updated_at': 'updatedAt',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LocalSetting.fromMap(Map<String, dynamic> map) {
    return LocalSetting(
      key: map['key'] as String,
      value: map['value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
}
