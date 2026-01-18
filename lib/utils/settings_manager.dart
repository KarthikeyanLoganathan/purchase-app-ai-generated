import 'package:flutter/foundation.dart';
import 'package:purchase_app/models/currency.dart';
import 'package:purchase_app/models/defaults.dart';
import 'package:purchase_app/models/unit_of_measure.dart';
import '../models/local_setting.dart';
import '../services/database_helper.dart';

/// Singleton class that manages application settings
/// Loads settings into memory on startup and provides reactive access via ValueNotifiers
class SettingsManager {
  static final SettingsManager instance = SettingsManager._init();
  SettingsManager._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // In-memory caches for master data
  static final Map<String, Currency> _currencies = {};
  static final Map<String, UnitOfMeasure> _unitOfMeasures = {};

  // ValueNotifiers for reactive updates
  final ValueNotifier<bool> developerMode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> syncPaused = ValueNotifier<bool>(false);
  final ValueNotifier<String?> webAppUrl = ValueNotifier<String?>(null);
  final ValueNotifier<String?> secretCode = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastSyncTimestamp = ValueNotifier<String?>(null);
  final ValueNotifier<String?> googleSheetId = ValueNotifier<String?>(null);
  final ValueNotifier<Currency> defaultCurrency =
      ValueNotifier<Currency>(Currency.inrCurrency);
  final ValueNotifier<UnitOfMeasure> defaultUnitOfMeasure =
      ValueNotifier<UnitOfMeasure>(UnitOfMeasure.nosUnitOfMeasure);

  /// Initialize settings from database
  /// Call this once during app startup
  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> loadDefaults() async {
    defaultCurrency.value =
        await _dbHelper.getDefaultCurrencyObject() ?? Currency.inrCurrency;
    defaultUnitOfMeasure.value =
        await _dbHelper.getDefaultUnitOfMeasureObject() ??
            UnitOfMeasure.nosUnitOfMeasure;
  }

  /// Load all currencies from database into memory cache
  Future<void> loadCurrencies() async {
    final currencies = await _dbHelper.getAllCurrencies();
    _currencies.clear();
    for (final currency in currencies) {
      _currencies[currency.name] = currency;
    }
  }

  /// Load all units of measure from database into memory cache
  Future<void> loadUnitOfMeasures() async {
    final units = await _dbHelper.getAllUnitsOfMeasure();
    _unitOfMeasures.clear();
    for (final unit in units) {
      _unitOfMeasures[unit.name] = unit;
    }
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
    await loadDefaults();
    await loadCurrencies();
    await loadUnitOfMeasures();
  }

  // Getters
  bool get isDeveloperMode => developerMode.value;
  bool get isSyncPaused => syncPaused.value;
  String? get getWebAppUrl => webAppUrl.value;
  String? get getSecretCode => secretCode.value;
  String? get getLastSyncTimestamp => lastSyncTimestamp.value;

  /// Get currency from cache by name
  Currency? getCurrency(String name) => _currencies[name];

  /// Get unit of measure from cache by name
  UnitOfMeasure? getUnitOfMeasure(String name) => _unitOfMeasures[name];

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

  Future<void> setDefault(Defaults? defaultItem) async {
    if (defaultItem != null) {
      if (defaultItem.type == DefaultsTypes.currency) {
        defaultCurrency.value =
            await _dbHelper.getDefaultCurrencyObject() ?? Currency.inrCurrency;
      } else if (defaultItem.type == DefaultsTypes.unitOfMeasure) {
        defaultUnitOfMeasure.value =
            await _dbHelper.getDefaultUnitOfMeasureObject() ??
                UnitOfMeasure.nosUnitOfMeasure;
      }
    } else {
      await loadDefaults();
    }
  }

  int getCurrencyDecimalPlaces(String name) {
    final currency = getCurrency(name);
    if (currency != null) {
      return currency.numberOfDecimalPlaces;
    }
    return 2; // Default
  }

  int getUnitOfMeasureDecimalPlaces(String name) {
    final unitOfMeasure = getUnitOfMeasure(name);
    if (unitOfMeasure != null) {
      return unitOfMeasure.numberOfDecimalPlaces;
    }
    if (name == UnitOfMeasures.percent) {
      return UnitOfMeasure.percentUnitOfMeasure.numberOfDecimalPlaces;
    }
    return 2; // Default
  }

  int getPercentDecimalPlaces() {
    return getUnitOfMeasureDecimalPlaces(UnitOfMeasures.percent);
  }

  List<Currency> get allCurrencies => _currencies.values.toList();
  List<UnitOfMeasure> get allUnitOfMeasures => _unitOfMeasures.values.toList();

  /// Dispose ValueNotifiers when app closes
  void dispose() {
    developerMode.dispose();
    syncPaused.dispose();
    webAppUrl.dispose();
    secretCode.dispose();
    lastSyncTimestamp.dispose();
    googleSheetId.dispose();
    defaultCurrency.dispose();
    defaultUnitOfMeasure.dispose();
  }
}
