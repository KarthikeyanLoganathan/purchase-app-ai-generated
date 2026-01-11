import 'package:flutter/foundation.dart';
import '../models/local_setting.dart';
import '../services/database_helper.dart';

/// Singleton class that manages application settings
/// Loads settings into memory on startup and provides reactive access via ValueNotifiers
class SettingsManager {
  static final SettingsManager instance = SettingsManager._init();

  SettingsManager._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ValueNotifiers for reactive updates
  final ValueNotifier<bool> developerMode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> syncPaused = ValueNotifier<bool>(false);
  final ValueNotifier<String?> webAppUrl = ValueNotifier<String?>(null);
  final ValueNotifier<String?> secretCode = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastSyncTimestamp = ValueNotifier<String?>(null);
  final ValueNotifier<String?> googleSheetId = ValueNotifier<String?>(null);

  /// Initialize settings from database
  /// Call this once during app startup
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Load all settings from database into memory
  Future<void> _loadSettings() async {
    final devMode =
        await _dbHelper.getLocalSetting(LocalSettingsKeys.developerMode);
    developerMode.value = devMode?.toUpperCase() == 'TRUE';

    final pause = await _dbHelper.getLocalSetting(LocalSettingsKeys.syncPaused);
    syncPaused.value = pause?.toUpperCase() == 'TRUE';

    webAppUrl.value =
        await _dbHelper.getLocalSetting(LocalSettingsKeys.webAppUrl);
    secretCode.value =
        await _dbHelper.getLocalSetting(LocalSettingsKeys.secretCode);
    lastSyncTimestamp.value =
        await _dbHelper.getLocalSetting(LocalSettingsKeys.lastSyncTimestamp);
    googleSheetId.value =
        await _dbHelper.getLocalSetting(LocalSettingsKeys.googleSheetId);
  }

  // Getters
  bool get isDeveloperMode => developerMode.value;
  bool get isSyncPaused => syncPaused.value;
  String? get getWebAppUrl => webAppUrl.value;
  String? get getSecretCode => secretCode.value;
  String? get getLastSyncTimestamp => lastSyncTimestamp.value;

  // Setters - update both memory and database
  Future<void> setDeveloperMode(bool value) async {
    await _dbHelper.setLocalSetting(
      LocalSettingsKeys.developerMode,
      value ? 'TRUE' : 'FALSE',
    );
    developerMode.value = value;
  }

  Future<void> setSyncPaused(bool value) async {
    await _dbHelper.setLocalSetting(
      LocalSettingsKeys.syncPaused,
      value ? 'TRUE' : 'FALSE',
    );
    syncPaused.value = value;
  }

  Future<void> setWebAppUrlAndSecretCode(
      String? iWebAppUrl, String? iSecretCode) async {
    if (iWebAppUrl != null) {
      await _dbHelper.setLocalSetting(LocalSettingsKeys.webAppUrl, iWebAppUrl);
    } else {
      await _dbHelper.deleteLocalSetting(LocalSettingsKeys.webAppUrl);
    }
    if (iSecretCode != null) {
      await _dbHelper.setLocalSetting(
          LocalSettingsKeys.secretCode, iSecretCode);
    } else {
      await _dbHelper.deleteLocalSetting(LocalSettingsKeys.secretCode);
    }
    webAppUrl.value = iWebAppUrl;
    secretCode.value = iSecretCode;
  }

  Future<void> setLastSyncTimestamp(String? value) async {
    if (value != null) {
      await _dbHelper.setLocalSetting(
          LocalSettingsKeys.lastSyncTimestamp, value);
    } else {
      await _dbHelper.deleteLocalSetting(LocalSettingsKeys.lastSyncTimestamp);
    }
    lastSyncTimestamp.value = value;
  }

  /// Check if user is logged in (has credentials)
  bool get isLoggedIn {
    return webAppUrl.value != null &&
        webAppUrl.value!.isNotEmpty &&
        secretCode.value != null &&
        secretCode.value!.isNotEmpty;
  }

  Future<void> setGoogleSheetId(String? value) async {
    if (value != null) {
      await _dbHelper.setLocalSetting(LocalSettingsKeys.googleSheetId, value);
    } else {
      await _dbHelper.deleteLocalSetting(LocalSettingsKeys.googleSheetId);
    }
    googleSheetId.value = value;
  }

  /// Dispose ValueNotifiers when app closes
  void dispose() {
    developerMode.dispose();
    syncPaused.dispose();
    webAppUrl.dispose();
    secretCode.dispose();
    lastSyncTimestamp.dispose();
    googleSheetId.dispose();
  }
}
